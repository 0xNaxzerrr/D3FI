use utoipa::OpenApi;
use crate::api::models::{
    HealthResponse, MarketStats, Asset, UserPortfolio,
    UserAsset, HealthInfo, Transaction
};

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::api::rest::health::health_check,
        crate::api::rest::market::get_market_stats,
        crate::api::rest::market::get_market_assets,
        crate::api::rest::market::get_market_rates,
        crate::api::rest::users::get_user_portfolio,
        crate::api::rest::users::get_user_health,
        crate::api::rest::users::get_user_history,
        crate::api::rest::users::get_user_current_health,
        crate::api::rest::users::get_user_health_history
    ),
    components(
        schemas(
            HealthResponse,
            MarketStats,
            Asset,
            UserPortfolio,
            UserAsset,
            HealthInfo,
            Transaction
        )
    ),
    tags(
        (name = "Health", description = "Health check endpoints"),
        (name = "Market", description = "Market data endpoints"),
        (name = "Users", description = "User-specific endpoints")
    ),
    info(
        title = "D3FI API Documentation",
        version = "1.0.0",
        description = "Documentation for the D3FI Backend API",
        license(
            name = "MIT",
            url = "https://opensource.org/licenses/MIT"
        ),
        contact(
            name = "D3FI Team",
            url = "https://github.com/D3FI"
        )
    )
)]
pub struct ApiDoc; 