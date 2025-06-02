use sqlx::PgPool;
use std::sync::Arc;
use crate::core::price_service::PriceService;
use crate::core::price_ws_service::PriceWebSocketService;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub price_service: Option<Arc<PriceService>>,
    pub price_ws_service: Option<Arc<PriceWebSocketService>>,
}

impl AppState {
    pub fn new(db: PgPool) -> Self {
        Self {
            db,
            price_service: None,
            price_ws_service: None,
        }
    }

    pub fn with_price_service(mut self, price_service: Arc<PriceService>) -> Self {
        self.price_service = Some(price_service);
        self
    }

    pub fn with_price_ws_service(mut self, price_ws_service: Arc<PriceWebSocketService>) -> Self {
        self.price_ws_service = Some(price_ws_service);
        self
    }
} 