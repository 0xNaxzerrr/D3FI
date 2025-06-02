use axum::Router;
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use dotenvy::dotenv;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;
use tokio::sync::broadcast;
use std::sync::Arc;

mod api;
mod blockchain;
mod config;
mod core;
mod db;
mod utils;

use api::state::AppState;
use core::price_service::PriceService;
use core::price_ws_service::PriceWebSocketService;
use api::ws::{WsState, WsMessage};
use api::ws_handler::ws_handler;

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
    
    // Initialize WsState for real-time updates
    let (tx, _rx) = broadcast::channel::<WsMessage>(100);
    let ws_state = WsState {
        pool: db_pool.clone(),
        tx,
    };
    
    // Initialize and start the PriceService
    let price_service = PriceService::new(db_pool.clone())
        .with_ws_state(ws_state.clone())
        .start()
        .await;
    
    // Initialize and start the PriceWebSocketService
    let price_ws_service = Arc::new(PriceWebSocketService::new());
    // Utiliser une clé API par défaut pour les tests si elle n'est pas définie
    let coinapi_key = std::env::var("COINAPI_KEY").unwrap_or_else(|_| {
        tracing::warn!("COINAPI_KEY non définie, utilisation d'une clé de test");
        "1269099a-de56-4f46-b7aa-575d582d239f".to_string()
    });
    price_ws_service.start(coinapi_key).await;
    tracing::info!("Service de prix en temps réel démarré - Connexion à CoinAPI");
    
    // Create application state with price service
    let app_state = AppState::new(db_pool.clone())
        .with_price_service(price_service)
        .with_price_ws_service(price_ws_service.clone());
    
    // Construire l'application avec le pool de connexion
    let app = Router::new()
        .merge(api::create_router_with_state(app_state))
        .route("/ws", axum::routing::get(move |ws| ws_handler(ws, price_ws_service.clone())));

    // Ajouter Swagger UI
    let app = app.merge(SwaggerUi::new("/swagger-ui")
        .url("/api-docs/openapi.json", api::ApiDoc::openapi()));

    // Définir l'adresse d'écoute
    let port = std::env::var("PORT").unwrap_or_else(|_| "3001".to_string()).parse::<u16>().unwrap_or(3001);
    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    tracing::info!("server listening on {}", addr);
    tracing::info!("Swagger UI available at http://{}/swagger-ui", addr);
    tracing::info!("WebSocket endpoint available at ws://{}/ws", addr);

    // Démarrer le serveur
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}