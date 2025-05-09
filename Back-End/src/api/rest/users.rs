use axum::{
    extract::Path,
    routing::get,
    Json, Router,
};
use crate::api::models::{UserPortfolio, UserAsset, HealthInfo, Transaction};

pub fn router() -> Router {
    Router::new()
        .route("/api/v1/users/:address/portfolio", get(get_user_portfolio))
        .route("/api/v1/users/:address/health", get(get_user_health))
        .route("/api/v1/users/:address/history", get(get_user_history))
        .route("/api/v1/users/:address/health/current", get(get_user_current_health))
        .route("/api/v1/users/:address/health/history", get(get_user_health_history))
}

/// Get user's portfolio information
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/portfolio",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User portfolio retrieved successfully", body = UserPortfolio)
    )
)]
pub async fn get_user_portfolio(Path(address): Path<String>) -> Json<UserPortfolio> {
    Json(UserPortfolio {
        address,
        supplied_assets: vec![
            UserAsset {
                symbol: "ETH".to_string(),
                amount: "10.5".to_string(),
                value_usd: "25000.00".to_string(),
            },
        ],
        borrowed_assets: vec![
            UserAsset {
                symbol: "USDC".to_string(),
                amount: "15000".to_string(),
                value_usd: "15000.00".to_string(),
            },
        ],
        health_factor: "1.8".to_string(),
    })
}

/// Get user's health information
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/health",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User health information retrieved successfully", body = HealthInfo)
    )
)]
pub async fn get_user_health(Path(_address): Path<String>) -> Json<HealthInfo> {
    Json(HealthInfo {
        current: "1.8".to_string(),
        threshold: "1.0".to_string(),
        status: "safe".to_string(),
    })
}

/// Get user's transaction history
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/history",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User transaction history retrieved successfully", body = Vec<Transaction>)
    )
)]
pub async fn get_user_history(Path(_address): Path<String>) -> Json<Vec<Transaction>> {
    Json(vec![
        Transaction {
            timestamp: 1680000000,
            tx_hash: "0x...".to_string(),
            action: "Supply".to_string(),
            asset: "ETH".to_string(),
            amount: "5.0".to_string(),
        },
        Transaction {
            timestamp: 1680100000,
            tx_hash: "0x...".to_string(),
            action: "Borrow".to_string(),
            asset: "USDC".to_string(),
            amount: "10000".to_string(),
        },
    ])
}

/// Get user's current health factor
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/health/current",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User current health factor retrieved successfully", body = String)
    )
)]
pub async fn get_user_current_health(Path(_address): Path<String>) -> Json<String> {
    Json("1.8".to_string())
}

/// Get user's health factor history
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/health/history",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User health factor history retrieved successfully", body = Vec<(u64, String)>)
    )
)]
pub async fn get_user_health_history(Path(_address): Path<String>) -> Json<Vec<(u64, String)>> {
    Json(vec![
        (1680000000, "2.1".to_string()),
        (1680100000, "1.9".to_string()),
        (1680200000, "1.8".to_string()),
    ])
}