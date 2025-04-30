mod rest;
mod ws;

use axum::Router;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

pub fn create_router() -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .merge(rest::health::router())
        .merge(rest::market::router())
        .merge(rest::users::router())
        .layer(TraceLayer::new_for_http())
        .layer(cors)
}
