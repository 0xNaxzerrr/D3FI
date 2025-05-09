pub mod rest;
pub mod ws;
pub mod openapi;
pub mod models;

use axum::Router;
use sqlx::PgPool;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

pub use openapi::ApiDoc;
pub use models::*;

pub fn create_router(pool: PgPool) -> Router {
    // Configurer CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Assembler le routeur principal
    Router::new()
        .merge(rest::health::router())
        .merge(rest::market::router(pool.clone()))
        .merge(rest::users::router())
        .layer(TraceLayer::new_for_http())
        .layer(cors)
}