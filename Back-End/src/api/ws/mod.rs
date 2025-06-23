use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    extract::State,
    response::IntoResponse,
    routing::get,
    Router,
};
use futures::{stream::StreamExt, SinkExt};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use std::collections::HashMap;
use tokio::sync::broadcast;

// Types pour les messages WebSocket
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "data")]
pub enum WsMessage {
    PriceUpdate(HashMap<String, String>),
    HealthFactorWarning {
        address: String,
        health_factor: String,
        threshold: String,
    },
    Liquidation {
        address: String,
        tx_hash: String,
    },
    Error(String),
}

// Structure pour le state du WebSocket
#[derive(Clone)]
pub struct WsState {
    pub pool: PgPool,
    pub tx: broadcast::Sender<WsMessage>,
}

pub fn router(pool: PgPool) -> Router {
    // Créer un canal broadcast pour diffuser les messages à tous les clients
    let (tx, _rx) = broadcast::channel::<WsMessage>(100);

    let state = WsState { pool, tx };

    Router::new()
        .route("/ws/prices", get(ws_handler))
        .with_state(state)
}

async fn ws_handler(ws: WebSocketUpgrade, State(state): State<WsState>) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(socket: WebSocket, state: WsState) {
    let (mut sender, mut receiver) = socket.split();

    // S'abonner au canal de diffusion
    let mut rx = state.tx.subscribe();

    // Tâche pour recevoir les messages du canal et les envoyer au client
    let mut send_task = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            if let Ok(json) = serde_json::to_string(&msg) {
                if sender.send(Message::Text(json)).await.is_err() {
                    break;
                }
            }
        }
    });

    // Tâche pour recevoir les messages du client
    let mut recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = receiver.next().await {
            match msg {
                Message::Text(text) => {
                    // On pourrait traiter des commandes spécifiques ici si nécessaire
                    tracing::debug!("Received message: {}", text);
                }
                Message::Close(_) => break,
                _ => {}
            }
        }
    });

    // Attendre que l'une des tâches se termine
    tokio::select! {
        _ = &mut send_task => recv_task.abort(),
        _ = &mut recv_task => send_task.abort(),
    }
}

// Fonction pour diffuser une mise à jour de prix à tous les clients WebSocket
pub async fn broadcast_price_update(state: &WsState, prices: HashMap<String, String>) {
    let message = WsMessage::PriceUpdate(prices);
    let _ = state.tx.send(message);
}

// Fonction pour diffuser un avertissement de health factor bas
pub async fn broadcast_health_factor_warning(
    state: &WsState,
    address: String,
    health_factor: String,
    threshold: String,
) {
    let message = WsMessage::HealthFactorWarning {
        address,
        health_factor,
        threshold,
    };
    let _ = state.tx.send(message);
}

// Fonction pour diffuser une notification de liquidation
pub async fn broadcast_liquidation(state: &WsState, address: String, tx_hash: String) {
    let message = WsMessage::Liquidation { address, tx_hash };
    let _ = state.tx.send(message);
}
