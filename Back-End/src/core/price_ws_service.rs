use std::sync::Arc;
use tokio::sync::broadcast::{self, Sender};
use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use serde::{Deserialize, Serialize};
use futures::{SinkExt, StreamExt};
use std::collections::HashMap;
use tokio::sync::RwLock;
use tracing::{info, error, debug};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PriceUpdate {
    pub symbol: String,
    pub price: f64,
    pub timestamp: String,
    pub exchange: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct CoinApiMessage {
    #[serde(rename = "type")]
    message_type: String,
    symbol_id: Option<String>,
    price: Option<f64>,
    time_coinapi: Option<String>,
}

pub struct PriceWebSocketService {
    prices: Arc<RwLock<HashMap<String, PriceUpdate>>>,
    broadcast_tx: Sender<PriceUpdate>,
}

impl PriceWebSocketService {
    pub fn new() -> Self {
        let (tx, _) = broadcast::channel(100);
        Self {
            prices: Arc::new(RwLock::new(HashMap::new())),
            broadcast_tx: tx,
        }
    }

    pub fn get_broadcast_receiver(&self) -> broadcast::Receiver<PriceUpdate> {
        self.broadcast_tx.subscribe()
    }

    pub async fn get_current_price(&self, symbol: &str) -> Option<PriceUpdate> {
        self.prices.read().await.get(symbol).cloned()
    }

    pub async fn start(&self, api_key: String) {
        let prices = Arc::clone(&self.prices);
        let tx = self.broadcast_tx.clone();

        tokio::spawn(async move {
            loop {
                info!("Démarrage de la connexion WebSocket pour les prix crypto...");
                match Self::connect_to_coinapi(&api_key, prices.clone(), tx.clone()).await {
                    Ok(_) => {
                        error!("WebSocket connection closed normally");
                    }
                    Err(e) => {
                        error!("WebSocket error: {}", e);
                    }
                }
                
                // Attendre avant de tenter une reconnexion
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
                info!("Tentative de reconnexion au WebSocket...");
            }
        });
    }

    async fn connect_to_coinapi(
        api_key: &str,
        prices: Arc<RwLock<HashMap<String, PriceUpdate>>>,
        tx: Sender<PriceUpdate>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        info!("Tentative de connexion à CoinAPI WebSocket...");
        let (ws_stream, _) = connect_async("wss://ws.coinapi.io/v1/").await?;
        info!("Connexion établie à CoinAPI WebSocket!");
        
        let (mut write, mut read) = ws_stream.split();

        // Message d'authentification
        let hello_msg = serde_json::json!({
            "type": "hello",
            "apikey": api_key,
            "subscribe_data_type": ["trade"],
            "subscribe_filter_symbol_id": [
                "BITSTAMP_SPOT_BTC_USD$",
                "BITSTAMP_SPOT_ETH_USD$"
            ],
        });

        info!("Envoi du message d'authentification à CoinAPI...");
        write.send(Message::Text(hello_msg.to_string())).await?;
        info!("Message d'authentification envoyé avec succès");

        while let Some(msg) = read.next().await {
            match msg {
                Ok(Message::Text(text)) => {
                    debug!("Message reçu: {}", text);
                    if let Ok(message) = serde_json::from_str::<CoinApiMessage>(&text) {
                        if let (Some(symbol_id), Some(price), Some(timestamp)) = 
                            (message.symbol_id.clone(), message.price, message.time_coinapi.clone()) {
                            
                            let token = Self::extract_token(&symbol_id);
                            if let Some(token) = token {
                                let update = PriceUpdate {
                                    symbol: token.clone(),
                                    price,
                                    timestamp,
                                    exchange: symbol_id.split("_").next().unwrap_or("UNKNOWN").to_string(),
                                };

                                info!("Prix mis à jour: {} = ${:.2} ({})", token, price, update.exchange);
                                
                                prices.write().await.insert(token, update.clone());
                                let _ = tx.send(update);
                            }
                        }
                    }
                }
                Ok(Message::Close(_)) => {
                    info!("Connexion WebSocket fermée par le serveur");
                    break;
                }
                Err(e) => {
                    error!("Erreur lors de la réception du message: {}", e);
                    break;
                }
                _ => {}
            }
        }

        Ok(())
    }

    fn extract_token(symbol_id: &str) -> Option<String> {
        symbol_id.split("_").nth(2).map(String::from)
    }
} 