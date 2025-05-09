use axum::{
    extract::State,
    routing::get,
    Router, Json,
};
use sqlx::PgPool;
use anyhow::Result;
use crate::db::postgres::AssetRepository;
use crate::db::models::Asset;
use crate::api::models::MarketStats;

pub fn router(pool: PgPool) -> Router {
    Router::new()
        .route("/api/v1/market/stats", get(get_market_stats))
        .route("/api/v1/market/assets", get(get_market_assets))
        .route("/api/v1/market/rates", get(get_market_rates))
        .with_state(pool)
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
    State(pool): State<PgPool>
) -> Result<Json<Vec<Asset>>, axum::http::StatusCode> {
    let repo = AssetRepository::new(pool);
    
    match repo.get_all_assets().await {
        Ok(assets) => Ok(Json(assets)),
        Err(e) => {
            tracing::error!("Failed to get assets: {:?}", e);
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
        (status = 200, description = "Market rates retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_market_rates(
    State(pool): State<PgPool>
) -> Result<Json<Vec<Asset>>, axum::http::StatusCode> {
    get_market_assets(State(pool)).await
}