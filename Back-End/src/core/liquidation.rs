use anyhow::Result;
use sqlx::PgPool;
use crate::core::{HealthFactorService, HealthFactorStatus, UserHealthFactor};
use crate::api::ws::{WsState, broadcast_health_factor_warning, broadcast_liquidation};

// Service de liquidation
pub struct LiquidationService {
    pool: PgPool,
    health_factor_service: HealthFactorService,
    ws_state: Option<WsState>,
}

impl LiquidationService {
    pub fn new(
        pool: PgPool, 
        health_factor_service: HealthFactorService
    ) -> Self {
        Self { 
            pool, 
            health_factor_service,
            ws_state: None,
        }
    }
    
    pub fn with_ws_state(mut self, ws_state: WsState) -> Self {
        self.ws_state = Some(ws_state);
        self
    }
    
    // Vérifier tous les utilisateurs et déclencher des liquidations si nécessaire
    pub async fn check_for_liquidations(&self) -> Result<()> {
        // Récupérer tous les utilisateurs à risque
        let at_risk_users = self.health_factor_service.check_all_users_health_factors().await?;
        
        for user in at_risk_users {
            match user.status {
                HealthFactorStatus::Liquidation => {
                    // Liquider l'utilisateur
                    match self.liquidate_user(&user.address).await {
                        Ok(tx_hash) => {
                            tracing::info!("User {} liquidated. Transaction hash: {}", user.address, tx_hash);
                            
                            // Notifier via WebSocket si disponible
                            if let Some(ws_state) = &self.ws_state {
                                broadcast_liquidation(
                                    ws_state, 
                                    user.address.clone(), 
                                    tx_hash
                                ).await;
                            }
                        },
                        Err(e) => {
                            tracing::error!("Failed to liquidate user {}: {:?}", user.address, e);
                        }
                    }
                },
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
                            crate::core::HEALTH_FACTOR_WARNING_THRESHOLD.to_string()
                        ).await;
                    }
                },
                _ => {}
            }
        }
        
        Ok(())
    }
    
    // Liquider un utilisateur spécifique via smart contract
    pub async fn liquidate_user(&self, address: &str) -> Result<String> {
        // Dans une implémentation réelle, cette méthode appellerait le smart contract
        // Pour l'instant, c'est un mock qui retourne un hash de transaction
        
        // TODO: Implémenter la logique réelle d'appel au smart contract via ethers-rs
        
        // Mock: On simule un hash de transaction
        let tx_hash = format!("0x{}", hex::encode(rand::random::<[u8; 32]>()));
        
        Ok(tx_hash)
    }
} 