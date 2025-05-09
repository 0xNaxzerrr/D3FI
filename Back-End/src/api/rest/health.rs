use axum::{
    routing::get,
    Router,
    Json,
};
use crate::api::models::HealthResponse;
use utoipa::ToSchema;

pub fn router() -> Router {
    Router::new()
        .route("/api/v1/health", get(health_check))
}

/// Check the health status of the API
#[utoipa::path(
    get,
    path = "/api/v1/health",
    tag = "Health",
    responses(
        (status = 200, description = "API health status", body = HealthResponse)
    )
)]
pub async fn health_check() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}