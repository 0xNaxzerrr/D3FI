use crate::api::ws::WsState;
use crate::core::price_ws_service::PriceWebSocketService;
use crate::db::models::SuppliedPosition;
use crate::db::postgres::{AssetRepository, PositionRepository};
use anyhow::Result;
use bigdecimal::BigDecimal;
use sqlx::PgPool;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, warn};

// Seuils de health factor
pub const HEALTH_FACTOR_LIQUIDATION_THRESHOLD: &str = "1.0";
pub const HEALTH_FACTOR_WARNING_THRESHOLD: &str = "1.2";

// Structure pour stocker les informations de health factor d'un utilisateur
#[derive(Debug, Clone)]
pub struct UserHealthFactor {
    pub address: String,
    pub health_factor: BigDecimal,
    pub status: HealthFactorStatus,
    pub total_collateral_value: BigDecimal,
    pub total_borrowed_value: BigDecimal,
}

// États possibles du health factor
#[derive(Debug, Clone)]
pub enum HealthFactorStatus {
    Safe,
    Warning,
    Liquidation,
}

impl HealthFactorStatus {
    pub fn from_health_factor(health_factor: &BigDecimal) -> Self {
        let liquidation_threshold =
            BigDecimal::from_str(HEALTH_FACTOR_LIQUIDATION_THRESHOLD).unwrap();
        let warning_threshold = BigDecimal::from_str(HEALTH_FACTOR_WARNING_THRESHOLD).unwrap();

        if health_factor <= &liquidation_threshold {
            HealthFactorStatus::Liquidation
        } else if health_factor <= &warning_threshold {
            HealthFactorStatus::Warning
        } else {
            HealthFactorStatus::Safe
        }
    }
}

// Service de gestion du health factor
pub struct HealthFactorService {
    pool: PgPool,
    price_ws_service: Arc<PriceWebSocketService>,
    ws_state: Option<WsState>,
    users_health_factor: Arc<RwLock<HashMap<String, UserHealthFactor>>>,
}

impl HealthFactorService {
    pub fn new(pool: PgPool, price_ws_service: Arc<PriceWebSocketService>) -> Self {
        Self {
            pool,
            price_ws_service,
            ws_state: None,
            users_health_factor: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub fn with_ws_state(mut self, ws_state: WsState) -> Self {
        self.ws_state = Some(ws_state);
        self
    }

    // Méthode principale pour vérifier périodiquement les health factors
    pub async fn start_monitoring(&self) {
        let users_health_factor = Arc::clone(&self.users_health_factor);
        let pool = self.pool.clone();
        let price_ws_service = Arc::clone(&self.price_ws_service);
        let ws_state = self.ws_state.clone();

        // Démarrer une tâche en arrière-plan pour surveiller les health factors
        tokio::spawn(async move {
            loop {
                // Vérifier les health factors toutes les 10 secondes
                match Self::check_all_users_health_factors(
                    &pool,
                    &price_ws_service,
                    &users_health_factor,
                )
                .await
                {
                    Ok(results) => {
                        for user_hf in results {
                            // Traiter les résultats selon le statut
                            match user_hf.status {
                                HealthFactorStatus::Liquidation => {
                                    // Alerter et déclencher la liquidation
                                    info!(
                                        "LIQUIDATION: Utilisateur {} a un health factor de {}",
                                        user_hf.address, user_hf.health_factor
                                    );

                                    // Envoyer une alerte via WebSocket si configuré
                                    if let Some(ws) = &ws_state {
                                        let tx_hash = Self::liquidate_user(&user_hf.address).await;
                                        if let Ok(hash) = tx_hash {
                                            crate::api::ws::broadcast_liquidation(
                                                ws,
                                                user_hf.address.clone(),
                                                hash,
                                            )
                                            .await;
                                        }
                                    }
                                }
                                HealthFactorStatus::Warning => {
                                    // Alerter sur un health factor faible
                                    warn!(
                                        "WARNING: Utilisateur {} a un health factor de {}",
                                        user_hf.address, user_hf.health_factor
                                    );

                                    // Envoyer une alerte via WebSocket si configuré
                                    if let Some(ws) = &ws_state {
                                        crate::api::ws::broadcast_health_factor_warning(
                                            ws,
                                            user_hf.address.clone(),
                                            user_hf.health_factor.to_string(),
                                            HEALTH_FACTOR_WARNING_THRESHOLD.to_string(),
                                        )
                                        .await;
                                    }
                                }
                                HealthFactorStatus::Safe => {
                                    // Tout va bien, rien à faire
                                }
                            }
                        }
                    }
                    Err(e) => {
                        error!("Erreur lors de la vérification des health factors: {}", e);
                    }
                }

                // Attendre avant la prochaine vérification
                tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;
            }
        });
    }

    // Vérifier les health factors de tous les utilisateurs
    pub async fn check_all_users_health_factors(
        pool: &PgPool,
        price_ws_service: &PriceWebSocketService,
        users_health_factor: &Arc<RwLock<HashMap<String, UserHealthFactor>>>,
    ) -> Result<Vec<UserHealthFactor>> {
        let position_repo = PositionRepository::new(pool.clone());

        // Récupérer tous les utilisateurs avec des positions
        let users = position_repo.get_all_users_with_positions().await?;
        let mut results = Vec::new();

        for user_address in users {
            match Self::calculate_user_health_factor(pool, price_ws_service, &user_address).await {
                Ok(health_factor) => {
                    // Mettre à jour le cache
                    users_health_factor
                        .write()
                        .await
                        .insert(user_address.clone(), health_factor.clone());
                    results.push(health_factor);
                }
                Err(e) => {
                    error!(
                        "Erreur lors du calcul du health factor pour {}: {}",
                        user_address, e
                    );
                }
            }
        }

        Ok(results)
    }

    // Méthode publique pour accéder aux résultats de la vérification
    pub async fn get_all_users_health_factors(&self) -> Result<Vec<UserHealthFactor>> {
        Self::check_all_users_health_factors(
            &self.pool,
            &self.price_ws_service,
            &self.users_health_factor,
        )
        .await
    }

    // Calculer le health factor d'un utilisateur spécifique
    pub async fn calculate_user_health_factor(
        pool: &PgPool,
        price_ws_service: &PriceWebSocketService,
        address: &str
    ) -> Result<UserHealthFactor> {
        let position_repo = PositionRepository::new(pool.clone());
        let asset_repo = AssetRepository::new(pool.clone());
        
        // Récupérer les positions fournies (collatérales)
        let supplied_positions = position_repo.get_user_supplied_positions(address).await?;
        let supplied_collateral_positions: Vec<&SuppliedPosition> = supplied_positions
            .iter()
            .filter(|pos| pos.collateral)
            .collect();
        
        // Récupérer les positions empruntées
        let borrowed_positions = position_repo.get_user_borrowed_positions(address).await?;
        
        // Calculer la valeur totale du collatéral
        let mut total_collateral_value = BigDecimal::from_str("0").unwrap();
        for position in &supplied_collateral_positions {
            // Récupérer l'actif par son ID
            let asset = match asset_repo.get_asset_by_id(position.asset_id).await? {
                Some(a) => a,
                None => {
                    error!("Asset non trouvé pour l'ID: {}", position.asset_id);
                    continue;
                }
            };
            
            // Utiliser le prix en temps réel si disponible
            let asset_price = if let Some(price_update) = price_ws_service.get_current_price(&asset.symbol).await {
                BigDecimal::from_str(&price_update.price.to_string()).unwrap_or(asset.price.clone())
            } else {
                asset.price.clone()
            };
            
            let position_value = &position.amount * &asset_price;
            total_collateral_value = total_collateral_value + position_value;
        }
        
        // Calculer la valeur totale empruntée
        let mut total_borrowed_value = BigDecimal::from_str("0").unwrap();
        for position in &borrowed_positions {
            let asset = match asset_repo.get_asset_by_id(position.asset_id).await? {
                Some(a) => a,
                None => {
                    error!("Asset non trouvé pour l'ID: {}", position.asset_id);
                    continue;
                }
            };
            
            // Utiliser le prix en temps réel si disponible
            let asset_price = if let Some(price_update) = price_ws_service.get_current_price(&asset.symbol).await {
                BigDecimal::from_str(&price_update.price.to_string()).unwrap_or(asset.price.clone())
            } else {
                asset.price.clone()
            };
            
            let position_value = &position.amount * &asset_price;
            total_borrowed_value = total_borrowed_value + position_value;
        }

        // Calculer le health factor
        let health_factor = if total_borrowed_value > BigDecimal::from_str("0").unwrap() {
            total_collateral_value.clone() / total_borrowed_value.clone()
        } else {
            // Si rien n'est emprunté, le health factor est considéré comme "infini"
            // On utilise une valeur arbitrairement élevée
            BigDecimal::from_str("1000").unwrap()
        };

        // Déterminer le statut
        let status = HealthFactorStatus::from_health_factor(&health_factor);

        // Enregistrer le health factor dans l'historique
        let _ = position_repo.save_health_factor(address, health_factor.clone()).await;

        Ok(UserHealthFactor {
            address: address.to_string(),
            health_factor,
            status,
            total_collateral_value,
            total_borrowed_value,
        })
    }

    // Appeler le smart contract pour liquider un utilisateur
    async fn liquidate_user(user_address: &str) -> Result<String> {
        // Vérifier si l'utilisateur a déjà été liquidé
        let pool = sqlx::Pool::connect(&std::env::var("DATABASE_URL").unwrap()).await?;
        let position_repo = PositionRepository::new(pool.clone());
        
        // Si l'utilisateur a déjà été liquidé, ne pas procéder à une nouvelle liquidation
        if position_repo.has_been_liquidated(user_address).await? {
            info!("L'utilisateur {} a déjà été liquidé, ignoré.", user_address);
            return Err(anyhow::anyhow!("L'utilisateur a déjà été liquidé"));
        }
        
        // Appeler la fonction du smart contract via ethers
        info!("Liquidation de l'utilisateur {}", user_address);
        
        // Appel au smart contract (à implémenter quand le contrat sera disponible)
        // Pour l'instant, simuler un hash de transaction
        let tx_hash = format!("0x{:x}", rand::random::<u128>());
        
        // Marquer toutes les positions de l'utilisateur comme liquidées
        position_repo.mark_user_positions_as_liquidated(user_address).await?;
        
        Ok(tx_hash)
    }
}
