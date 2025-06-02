use crate::api::ws::{broadcast_health_factor_warning, broadcast_liquidation, WsState};
use crate::blockchain::client::LiquidationContract;
use crate::core::price_ws_service::PriceWebSocketService;
use crate::core::{HealthFactorService, HealthFactorStatus};
use anyhow::{Context, Result};
use sqlx::PgPool;
use std::sync::Arc;
use tracing::{error, info};

// Service de liquidation
pub struct LiquidationService {
    pool: PgPool,
    health_factor_service: Arc<HealthFactorService>,
    price_ws_service: Arc<PriceWebSocketService>,
    liquidation_contract: Option<LiquidationContract>,
    ws_state: Option<WsState>,
    contract_address: String,
}

impl LiquidationService {
    pub fn new(
        pool: PgPool,
        health_factor_service: Arc<HealthFactorService>,
        price_ws_service: Arc<PriceWebSocketService>,
        contract_address: String,
    ) -> Self {
        Self {
            pool,
            health_factor_service,
            price_ws_service,
            liquidation_contract: None,
            ws_state: None,
            contract_address,
        }
    }

    pub fn with_ws_state(mut self, ws_state: WsState) -> Self {
        self.ws_state = Some(ws_state);
        self
    }

    pub async fn initialize(&mut self) -> Result<()> {
        // Initialiser le contrat de liquidation
        match LiquidationContract::new(&self.contract_address).await {
            Ok(contract) => {
                info!("Contrat de liquidation initialisé avec succès");
                self.liquidation_contract = Some(contract);
                Ok(())
            }
            Err(e) => {
                error!(
                    "Erreur lors de l'initialisation du contrat de liquidation: {}",
                    e
                );
                Err(e)
            }
        }
    }

    pub async fn start_monitoring(&self) {
        info!("Démarrage du service de surveillance des liquidations");

        // Laisser le service de health factor démarrer son propre monitoring
        self.health_factor_service.start_monitoring().await;
    }

    // Vérifier tous les utilisateurs et déclencher des liquidations si nécessaire
    pub async fn check_for_liquidations(&self) -> Result<()> {
        // Récupérer tous les utilisateurs à risque
        let at_risk_users = self
            .health_factor_service
            .get_all_users_health_factors()
            .await?;

        for user in at_risk_users {
            match user.status {
                HealthFactorStatus::Liquidation => {
                    // Liquider l'utilisateur
                    match self.liquidate_user(&user.address).await {
                        Ok(tx_hash) => {
                            tracing::info!(
                                "User {} liquidated. Transaction hash: {}",
                                user.address,
                                tx_hash
                            );

                            // Notifier via WebSocket si disponible
                            if let Some(ws_state) = &self.ws_state {
                                broadcast_liquidation(ws_state, user.address.clone(), tx_hash)
                                    .await;
                            }
                        }
                        Err(e) => {
                            tracing::error!("Failed to liquidate user {}: {:?}", user.address, e);
                        }
                    }
                }
                HealthFactorStatus::Warning => {
                    // Émettre un avertissement
                    tracing::warn!(
                        "User {} health factor is at warning level: {}",
                        user.address,
                        user.health_factor
                    );

                    // Notifier via WebSocket si disponible
                    if let Some(ws_state) = &self.ws_state {
                        broadcast_health_factor_warning(
                            ws_state,
                            user.address.clone(),
                            user.health_factor.to_string(),
                            crate::core::HEALTH_FACTOR_WARNING_THRESHOLD.to_string(),
                        )
                        .await;
                    }
                }
                _ => {}
            }
        }

        Ok(())
    }

    // Liquider un utilisateur spécifique
    pub async fn liquidate_user(&self, address: &str) -> Result<String> {
        // Vérifier que le contrat est initialisé
        let contract = match &self.liquidation_contract {
            Some(contract) => contract,
            None => return Err(anyhow::anyhow!("Contrat de liquidation non initialisé")),
        };

        // Récupérer les prix actuels pour BTC et ETH
        let btc_price = self
            .price_ws_service
            .get_current_price("BTC")
            .await
            .context("Prix BTC non disponible")?;

        let eth_price = self
            .price_ws_service
            .get_current_price("ETH")
            .await
            .context("Prix ETH non disponible")?;

        // Appeler le contrat pour liquider l'utilisateur
        info!("Liquidation de l'utilisateur {}", address);

        let tx_hash = contract
            .liquidate_user(address, &btc_price, &eth_price)
            .await?;

        // Envoyer une notification via WebSocket
        if let Some(ws_state) = &self.ws_state {
            crate::api::ws::broadcast_liquidation(ws_state, address.to_string(), tx_hash.clone())
                .await;
        }

        Ok(tx_hash)
    }
}
