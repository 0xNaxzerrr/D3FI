use std::collections::HashMap;
use anyhow::Result;
use sqlx::PgPool;
use sqlx::types::BigDecimal;
use rust_decimal::Decimal;
use std::str::FromStr;
use crate::db::postgres::{PositionRepository, AssetRepository};
use crate::db::models::{SuppliedPosition, BorrowedPosition};
use crate::core::PriceService;

// Seuils pour le health factor
pub const HEALTH_FACTOR_LIQUIDATION_THRESHOLD: &str = "1.0";
pub const HEALTH_FACTOR_WARNING_THRESHOLD: &str = "1.2";

// Structure pour stocker les informations du health factor d'un utilisateur
#[derive(Debug, Clone)]
pub struct UserHealthFactor {
    pub address: String,
    pub health_factor: BigDecimal,
    pub status: HealthFactorStatus,
    pub collateral_value: BigDecimal,
    pub borrowed_value: BigDecimal,
}

#[derive(Debug, Clone, PartialEq)]
pub enum HealthFactorStatus {
    Safe,
    Warning,
    Liquidation,
}

impl HealthFactorStatus {
    pub fn from_health_factor(health_factor: &BigDecimal) -> Self {
        let liquidation = BigDecimal::from_str(HEALTH_FACTOR_LIQUIDATION_THRESHOLD).unwrap();
        let warning = BigDecimal::from_str(HEALTH_FACTOR_WARNING_THRESHOLD).unwrap();
        
        if health_factor < &liquidation {
            Self::Liquidation
        } else if health_factor < &warning {
            Self::Warning
        } else {
            Self::Safe
        }
    }
}

// Service de gestion du health factor
pub struct HealthFactorService {
    pool: PgPool,
    price_service: std::sync::Arc<PriceService>,
}

impl HealthFactorService {
    pub fn new(pool: PgPool, price_service: std::sync::Arc<PriceService>) -> Self {
        Self { pool, price_service }
    }
    
    // Calculer le health factor pour tous les utilisateurs et retourner ceux qui sont à risque
    pub async fn check_all_users_health_factors(&self) -> Result<Vec<UserHealthFactor>> {
        let position_repo = PositionRepository::new(self.pool.clone());
        let asset_repo = AssetRepository::new(self.pool.clone());
        let user_repo = crate::db::postgres::UserRepository::new(self.pool.clone());
        
        let users = user_repo.get_all_users().await?;
        let mut at_risk_users = Vec::new();
        
        for user in users {
            let health_factor = self.calculate_user_health_factor(&user.address).await?;
            
            // Si le health factor est sous le warning threshold ou liquidation threshold
            if health_factor.status != HealthFactorStatus::Safe {
                // Sauvegarder l'historique du health factor
                position_repo.save_health_factor(&user.address, health_factor.health_factor.clone()).await?;
                
                // Ajouter l'utilisateur à la liste des utilisateurs à risque
                at_risk_users.push(health_factor);
            }
        }
        
        Ok(at_risk_users)
    }
    
    // Calculer le health factor pour un utilisateur spécifique
    pub async fn calculate_user_health_factor(&self, address: &str) -> Result<UserHealthFactor> {
        let position_repo = PositionRepository::new(self.pool.clone());
        
        // Récupérer les positions de l'utilisateur
        let supplied_positions = position_repo.get_user_supplied_positions(address).await?;
        let borrowed_positions = position_repo.get_user_borrowed_positions(address).await?;
        
        // Si l'utilisateur n'a pas de positions, retourner un health factor par défaut
        if supplied_positions.is_empty() && borrowed_positions.is_empty() {
            return Ok(UserHealthFactor {
                address: address.to_string(),
                health_factor: BigDecimal::from_str("0.0")?,
                status: HealthFactorStatus::Safe,
                collateral_value: BigDecimal::from_str("0.0")?,
                borrowed_value: BigDecimal::from_str("0.0")?,
            });
        }
        
        // Calculer la valeur du collatéral
        let mut collateral_value = BigDecimal::from_str("0.0")?;
        for position in &supplied_positions {
            if position.collateral {
                if let Some(price) = self.price_service.get_price(&self.get_asset_symbol(position.asset_id).await?).await {
                    let position_value = &position.amount * &price;
                    collateral_value = &collateral_value + &position_value;
                }
            }
        }
        
        // Calculer la valeur empruntée
        let mut borrowed_value = BigDecimal::from_str("0.0")?;
        for position in &borrowed_positions {
            if let Some(price) = self.price_service.get_price(&self.get_asset_symbol(position.asset_id).await?).await {
                let position_value = &position.amount * &price;
                borrowed_value = &borrowed_value + &position_value;
            }
        }
        
        // Calculer le health factor
        let health_factor = if borrowed_value > BigDecimal::from_str("0.0")? {
            &collateral_value / &borrowed_value
        } else {
            // Si l'utilisateur n'a pas d'emprunts, son health factor est "infini" (mettons une valeur très élevée)
            BigDecimal::from_str("100.0")?
        };
        
        let status = HealthFactorStatus::from_health_factor(&health_factor);
        
        Ok(UserHealthFactor {
            address: address.to_string(),
            health_factor,
            status,
            collateral_value,
            borrowed_value,
        })
    }
    
    // Récupérer le symbole d'un asset à partir de son ID
    async fn get_asset_symbol(&self, asset_id: uuid::Uuid) -> Result<String> {
        let asset_repo = AssetRepository::new(self.pool.clone());
        let assets = asset_repo.get_all_assets().await?;
        
        for asset in assets {
            if asset.id == asset_id {
                return Ok(asset.symbol);
            }
        }
        
        anyhow::bail!("Asset with ID {} not found", asset_id)
    }
} 