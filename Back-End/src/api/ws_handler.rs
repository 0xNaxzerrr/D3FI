use axum::{
    extract::ws::{WebSocket, WebSocketUpgrade},
    response::Response,
};
use std::sync::Arc;
use futures::{sink::SinkExt, stream::StreamExt};
use serde_json::json;
use crate::core::price_ws_service::PriceWebSocketService;

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    price_service: Arc<PriceWebSocketService>,
) -> Response {
    ws.on_upgrade(|socket| handle_socket(socket, price_service))
}

async fn handle_socket(socket: WebSocket, price_service: Arc<PriceWebSocketService>) {
    let (mut sender, _) = socket.split();
    let mut rx = price_service.get_broadcast_receiver();

    while let Ok(price_update) = rx.recv().await {
        let msg = json!({
            "type": "price_update",
            "data": price_update
        });

        if let Err(e) = sender.send(axum::extract::ws::Message::Text(msg.to_string())).await {
            eprintln!("Error sending WebSocket message: {}", e);
            break;
        }
    }
} 