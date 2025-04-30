use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};
use serde::Serialize;
use std::sync::Arc;

#[derive(Serialize)]
struct UserPortfolio {
    address: String,
    supplied_assets: Vec<UserAsset>,
    borrowed_assets: Vec<UserAsset>,
    health_factor: String,
}

#[derive(Serialize)]
struct UserAsset {
    symbol: String,
    amount: String,
    value_usd: String,
}

#[derive(Serialize)]
struct HealthInfo {
    current: String,
    threshold: String,
    status: String,
}

#[derive(Serialize)]
struct Transaction {
    timestamp: u64,
    tx_hash: String,
    action: String,
    asset: String,
    amount: String,
}

pub fn router() -> Router {
    Router::new()
        .route("/api/v1/users/:address/portfolio", get(get_user_portfolio))
        .route("/api/v1/users/:address/health", get(get_user_health))
        .route("/api/v1/users/:address/history", get(get_user_history))
        .route("/api/v1/users/:address/health/current", get(get_user_current_health))
        .route("/api/v1/users/:address/health/history", get(get_user_health_history))
}

async fn get_user_portfolio(Path(address): Path<String>) -> Json<UserPortfolio> {
    // Placeholder - À remplacer par l'appel réel au service
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

async fn get_user_health(Path(address): Path<String>) -> Json<HealthInfo> {
    // Placeholder - À remplacer par l'appel réel au service
    Json(HealthInfo {
        current: "1.8".to_string(),
        threshold: "1.0".to_string(),
        status: "safe".to_string(),
    })
}

async fn get_user_history(Path(address): Path<String>) -> Json<Vec<Transaction>> {
    // Placeholder - À remplacer par l'appel réel au service
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

async fn get_user_current_health(Path(address): Path<String>) -> Json<String> {
    // Placeholder - À remplacer par l'appel réel au service
    Json("1.8".to_string())
}

async fn get_user_health_history(Path(address): Path<String>) -> Json<Vec<(u64, String)>> {
    // Placeholder - Retourne un historique de health factor avec timestamp
    Json(vec![
        (1680000000, "2.1".to_string()),
        (1680100000, "1.9".to_string()),
        (1680200000, "1.8".to_string()),
    ])
}