use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod api;
mod blockchain;
mod config;
mod core;
mod db;
mod utils;

#[tokio::main]
async fn main() {
    // Initialiser le logging
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Construire l'application
    let app = api::create_router();

    // Définir l'adresse d'écoute
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    tracing::info!("server listening on {}", addr);

    // Démarrer le serveur
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}