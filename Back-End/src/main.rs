use axum::Router;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::broadcast;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod api;
mod blockchain;
mod config;
mod core;
mod db;
mod utils;

use api::state::AppState;
use api::ws::{WsMessage, WsState};
use api::ws_handler::ws_handler;
use core::price_service::PriceService;
use core::price_ws_service::PriceWebSocketService;

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

    // Initialize HealthFactorService
    let health_factor_service = Arc::new(
        core::health_factor::HealthFactorService::new(
            db_pool.clone(),
            Arc::clone(&price_ws_service),
        )
        .with_ws_state(ws_state.clone()),
    );

    // Initialize LiquidationService (si l'adresse du contrat est définie)
    let contract_address = std::env::var("CONTRACT_ADDRESS_LIQUIDATION").unwrap_or_else(|_| {
        tracing::warn!(
            "CONTRACT_ADDRESS_LIQUIDATION non définie, utilisation d'une adresse de test"
        );
        "0x5FbDB2315678afecb367f032d93F642f64180aa3".to_string() // Adresse de test
    });

    let mut liquidation_service = core::liquidation::LiquidationService::new(
        db_pool.clone(),
        Arc::clone(&health_factor_service),
        Arc::clone(&price_ws_service),
        contract_address,
    )
    .with_ws_state(ws_state.clone());

    // Initialiser le contrat de liquidation (facultatif, le service fonctionnera quand même sans)
    if let Err(e) = liquidation_service.initialize().await {
        tracing::warn!("Impossible d'initialiser le contrat de liquidation: {}", e);
        tracing::info!("Le service fonctionnera sans liquidation automatique");
    }

    // Démarrer le service de liquidation
    liquidation_service.start_monitoring().await;
    tracing::info!("Service de surveillance des liquidations démarré");

    // Create application state with price service
    let app_state = AppState::new(db_pool.clone())
        .with_price_service(price_service)
        .with_price_ws_service(price_ws_service.clone());

    // Construire l'application avec le pool de connexion
    let app = Router::new()
        .merge(api::create_router_with_state(app_state))
        .route(
            "/ws",
            axum::routing::get(move |ws| ws_handler(ws, price_ws_service.clone())),
        );

    // Ajouter Swagger UI
    let app = app
        .merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", api::ApiDoc::openapi()));

    // Définir l'adresse d'écoute
    let host = std::env::var("API_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = std::env::var("API_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or(8080);
    let addr = format!("{}:{}", host, port).parse::<SocketAddr>()?;
    tracing::info!("server listening on {}", addr);
    tracing::info!("Swagger UI available at http://{}/swagger-ui", addr);
    tracing::info!("WebSocket endpoint available at ws://{}/ws", addr);

    // Démarrer le serveur
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
