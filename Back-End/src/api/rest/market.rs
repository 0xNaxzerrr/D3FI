use axum::{
    extract::State,
    routing::get,
    Router, Json,
};
use sqlx::PgPool;
use anyhow::Result;
use crate::db::postgres::AssetRepository;
use crate::db::models::Asset;

pub fn router(pool: PgPool) -> Router {
    Router::new()
        .route("/api/v1/market/stats", get(get_market_stats))
        .route("/api/v1/market/assets", get(get_market_assets))
        .route("/api/v1/market/rates", get(get_market_rates))
        .with_state(pool)
}

async fn get_market_stats() -> Json<serde_json::Value> {
    // Pour l'instant, on garde des données factices pour cet endpoint
    Json(serde_json::json!({
        "total_supplied": "10000000",
        "total_borrowed": "5000000",
        "active_users": 1500
    }))
}

async fn get_market_assets(
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

async fn get_market_rates(
    State(pool): State<PgPool>
) -> Result<Json<Vec<Asset>>, axum::http::StatusCode> {
    // Pour les taux, on utilise aussi les données des assets
    get_market_assets(State(pool)).await
}