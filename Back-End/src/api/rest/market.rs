use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};

use crate::api::models::{Asset as ApiAsset, MarketStats};
use crate::api::state::AppState;
use crate::db::models::Asset;
use crate::db::postgres::AssetRepository;
use anyhow::Result;

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/api/v1/market/stats", get(get_market_stats))
        .route("/api/v1/market/assets", get(get_market_assets))
        .route("/api/v1/market/rates", get(get_market_rates))
        .route("/api/v1/market/assets/:symbol", get(get_asset_by_symbol))
        .route("/api/v1/market/prices", get(get_all_prices))
        .route("/market/prices", get(get_prices))
        .with_state(state)
}

/// Get global market statistics
#[utoipa::path(
    get,
    path = "/api/v1/market/stats",
    tag = "Market",
    responses(
        (status = 200, description = "Market statistics retrieved successfully", body = MarketStats)
    )
)]
pub async fn get_market_stats() -> Json<MarketStats> {
    Json(MarketStats {
        total_supplied: "10000000".to_string(),
        total_borrowed: "5000000".to_string(),
        active_users: 1500,
    })
}

/// Get all available market assets
#[utoipa::path(
    get,
    path = "/api/v1/market/assets",
    tag = "Market",
    responses(
        (status = 200, description = "List of market assets retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_market_assets(
    State(state): State<AppState>,
) -> Result<Json<Vec<Asset>>, axum::http::StatusCode> {
    let repo = AssetRepository::new(state.db);

    match repo.get_all_assets().await {
        Ok(assets) => Ok(Json(assets)),
        Err(e) => {
            tracing::error!("Failed to get assets: {:?}", e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Get asset by symbol
#[utoipa::path(
    get,
    path = "/api/v1/market/assets/{symbol}",
    tag = "Market",
    params(
        ("symbol" = String, Path, description = "Asset symbol (e.g., 'ETH', 'USDC')")
    ),
    responses(
        (status = 200, description = "Asset retrieved successfully", body = Asset),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_asset_by_symbol(
    State(state): State<AppState>,
    Path(symbol): Path<String>,
) -> Result<Json<Asset>, axum::http::StatusCode> {
    let repo = AssetRepository::new(state.db);

    match repo.get_asset_by_symbol(&symbol).await {
        Ok(Some(asset)) => Ok(Json(asset)),
        Ok(None) => Err(axum::http::StatusCode::NOT_FOUND),
        Err(e) => {
            tracing::error!("Failed to get asset {}: {:?}", symbol, e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Get all asset prices
#[utoipa::path(
    get,
    path = "/api/v1/market/prices",
    tag = "Market",
    responses(
        (status = 200, description = "List of asset prices retrieved successfully", body = Vec<(String, String)>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_all_prices(
    State(state): State<AppState>,
) -> Result<Json<Vec<(String, String)>>, axum::http::StatusCode> {
    let repo = AssetRepository::new(state.db);

    match repo.get_all_assets().await {
        Ok(assets) => {
            let prices = assets
                .into_iter()
                .map(|asset| (asset.symbol, asset.price.to_string()))
                .collect();
            Ok(Json(prices))
        }
        Err(e) => {
            tracing::error!("Failed to get asset prices: {:?}", e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Get current market rates for all assets
#[utoipa::path(
    get,
    path = "/api/v1/market/rates",
    tag = "Market",
    responses(
        (status = 200, description = "Market rates retrieved successfully", body = Vec<ApiAsset>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_market_rates(
    State(state): State<AppState>,
) -> Result<Json<Vec<ApiAsset>>, axum::http::StatusCode> {
    // Try to get real-time prices from the price service if available
    let use_price_service = state.price_service.is_some();

    // Get basic asset data from database
    let repo = AssetRepository::new(state.db);
    match repo.get_all_assets().await {
        Ok(db_assets) => {
            let mut api_assets = Vec::new();

            // Get real-time prices if the price service is available
            let real_time_prices = if use_price_service {
                match &state.price_service {
                    Some(price_service) => {
                        let prices = price_service.get_all_prices().await;
                        Some(prices)
                    }
                    None => None,
                }
            } else {
                None
            };

            for asset in db_assets {
                // Get price from real-time service or fallback to database
                let price = if let Some(prices) = &real_time_prices {
                    match prices.get(&asset.symbol) {
                        Some(real_time_price) => real_time_price.to_string(),
                        None => asset.price.to_string(),
                    }
                } else {
                    asset.price.to_string()
                };

                // Create API asset with rates information
                api_assets.push(ApiAsset {
                    symbol: asset.symbol,
                    price,
                    total_supply: "1000000".to_string(), // Example values
                    total_borrowed: "500000".to_string(),
                    supply_apy: "4.5".to_string(),
                    borrow_apy: "6.8".to_string(),
                });
            }

            Ok(Json(api_assets))
        }
        Err(e) => {
            tracing::error!("Failed to get market rates: {:?}", e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

async fn get_prices(State(state): State<AppState>) -> axum::Json<serde_json::Value> {
    // Récupérer les prix actuels depuis le service WebSocket via l'état global
    let mut prices = serde_json::json!({});

    // Récupérer les prix du service WebSocket si disponible
    if let Some(ws_service) = &state.price_ws_service {
        if let Some(btc_price) = ws_service.get_current_price("BTC").await {
            prices["BTC"] = serde_json::json!({
                "price": btc_price.price,
                "timestamp": btc_price.timestamp,
                "exchange": btc_price.exchange
            });
        }

        if let Some(eth_price) = ws_service.get_current_price("ETH").await {
            prices["ETH"] = serde_json::json!({
                "price": eth_price.price,
                "timestamp": eth_price.timestamp,
                "exchange": eth_price.exchange
            });
        }
    } else {
        // Fallback sur les prix de la base de données
        let repo = AssetRepository::new(state.db);
        if let Ok(assets) = repo.get_all_assets().await {
            for asset in assets {
                if asset.symbol == "BTC" || asset.symbol == "ETH" {
                    prices[asset.symbol] = serde_json::json!({
                        "price": asset.price.to_string(),
                        "timestamp": chrono::Utc::now().to_rfc3339(),
                        "exchange": "DATABASE"
                    });
                }
            }
        }
    }

    // Retourner les prix
    axum::Json(serde_json::json!({
        "success": true,
        "data": prices,
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}
