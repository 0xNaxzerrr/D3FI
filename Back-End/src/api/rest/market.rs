use axum::{
    routing::get,
    Router,
    Json,
    extract::State,
};
use serde::Serialize;
use std::sync::Arc;

#[derive(Serialize)]
struct MarketStats {
    total_supplied: String,
    total_borrowed: String,
    active_users: u64,
}

#[derive(Serialize)]
struct Asset {
    symbol: String,
    address: String,
    supply_apy: String,
    borrow_apy: String,
    total_supplied: String,
    total_borrowed: String,
}

pub fn router() -> Router {
    Router::new()
        .route("/api/v1/market/stats", get(get_market_stats))
        .route("/api/v1/market/assets", get(get_market_assets))
        .route("/api/v1/market/rates", get(get_market_rates))
}

async fn get_market_stats() -> Json<MarketStats> {
    // Placeholder - À remplacer par l'appel réel au service
    Json(MarketStats {
        total_supplied: "10000000".to_string(),
        total_borrowed: "5000000".to_string(),
        active_users: 1500,
    })
}

async fn get_market_assets() -> Json<Vec<Asset>> {
    // Placeholder - À remplacer par l'appel réel au service
    let assets = vec![
        Asset {
            symbol: "ETH".to_string(),
            address: "0x...".to_string(),
            supply_apy: "2.5".to_string(),
            borrow_apy: "3.2".to_string(),
            total_supplied: "5000".to_string(),
            total_borrowed: "3000".to_string(),
        },
        Asset {
            symbol: "USDC".to_string(),
            address: "0x...".to_string(),
            supply_apy: "3.1".to_string(),
            borrow_apy: "4.5".to_string(),
            total_supplied: "2000000".to_string(),
            total_borrowed: "1500000".to_string(),
        },
    ];
    
    Json(assets)
}

async fn get_market_rates() -> Json<Vec<Asset>> {
    // Pour l'instant, on réutilise la même structure pour les taux
    get_market_assets().await
}