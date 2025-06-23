pub mod models;
pub mod openapi;
pub mod rest;
pub mod state;
pub mod ws;
pub mod ws_handler;

use axum::Router;
use sqlx::PgPool;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

pub use openapi::ApiDoc;
pub use state::AppState;

pub fn create_router(pool: PgPool) -> Router {
    let state = AppState::new(pool.clone());
    create_router_with_state(state)
}

pub fn create_router_with_state(state: AppState) -> Router {
    // Create a WsState for WebSocket connections
    let (tx, _rx) = tokio::sync::broadcast::channel::<ws::WsMessage>(100);
    let _ws_state = ws::WsState {
        pool: state.db.clone(),
        tx,
    };

    // Configurer CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Assembler le routeur principal
    Router::new()
        .merge(rest::health::router())
        .merge(rest::market::router(state.clone()))
        .merge(rest::users::router(state.clone()))
        .merge(ws::router(state.db.clone()))
        .layer(TraceLayer::new_for_http())
        .layer(cors)
}
