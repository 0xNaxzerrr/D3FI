use serde::{Serialize, Deserialize};
use utoipa::ToSchema;

#[derive(Serialize, Deserialize, ToSchema)]
pub struct HealthResponse {
    /// Status of the API
    pub status: String,
    /// Version of the API
    pub version: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct MarketStats {
    /// Total amount supplied to the protocol
    pub total_supplied: String,
    /// Total amount borrowed from the protocol
    pub total_borrowed: String,
    /// Number of active users
    pub active_users: i32,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct Asset {
    /// Symbol of the asset (e.g., "ETH", "USDC")
    pub symbol: String,
    /// Current price of the asset in USD
    pub price: String,
    /// Total supply of the asset in the protocol
    pub total_supply: String,
    /// Total amount borrowed of this asset
    pub total_borrowed: String,
    /// Supply APY for this asset
    pub supply_apy: String,
    /// Borrow APY for this asset
    pub borrow_apy: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct UserPortfolio {
    /// Ethereum address of the user
    pub address: String,
    /// List of assets supplied by the user
    pub supplied_assets: Vec<UserAsset>,
    /// List of assets borrowed by the user
    pub borrowed_assets: Vec<UserAsset>,
    /// Current health factor of the user's position
    pub health_factor: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct UserAsset {
    /// Symbol of the asset
    pub symbol: String,
    /// Amount of the asset
    pub amount: String,
    /// USD value of the asset
    pub value_usd: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct HealthInfo {
    /// Current health factor
    pub current: String,
    /// Minimum health factor threshold
    pub threshold: String,
    /// Status of the position (safe, warning, danger)
    pub status: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct Transaction {
    /// Timestamp of the transaction
    pub timestamp: u64,
    /// Transaction hash
    pub tx_hash: String,
    /// Type of action (Supply, Borrow, Repay, Withdraw)
    pub action: String,
    /// Asset involved in the transaction
    pub asset: String,
    /// Amount of the asset
    pub amount: String,
} 