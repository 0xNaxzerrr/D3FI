use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use dotenvy::dotenv;

mod api;
mod blockchain;
mod config;
mod core;
mod db;
mod utils;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Charger les variables d'environnement depuis .env
    dotenvy::dotenv().ok();

    // Initialiser le logging
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Initialiser la connexion à la base de données
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let db_pool = db::init_db_pool(&database_url).await?;
    
    // Exécuter les migrations
    sqlx::migrate!("./migrations").run(&db_pool).await?;
    
    // Construire l'application avec le pool de connexion
    let app = api::create_router(db_pool);

    // Définir l'adresse d'écoute
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    tracing::info!("server listening on {}", addr);

    // Démarrer le serveur
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}