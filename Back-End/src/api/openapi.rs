use utoipa::OpenApi;
use crate::api::models::{
    HealthResponse, MarketStats, Asset, UserPortfolio,
    UserAsset, HealthInfo, Transaction
};
use crate::db::models::{SuppliedPosition, BorrowedPosition};
use crate::api::rest::users::{SupplyRequest, BorrowRequest};

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::api::rest::health::health_check,
        crate::api::rest::market::get_market_stats,
        crate::api::rest::market::get_market_assets,
        crate::api::rest::market::get_market_rates,
        crate::api::rest::market::get_asset_by_symbol,
        crate::api::rest::market::get_all_prices,
        crate::api::rest::users::get_user_portfolio,
        crate::api::rest::users::get_user_health,
        crate::api::rest::users::get_user_history,
        crate::api::rest::users::get_user_current_health,
        crate::api::rest::users::get_user_health_history,
        crate::api::rest::users::supply_asset,
        crate::api::rest::users::borrow_asset,
        crate::api::rest::users::get_supplied_positions,
        crate::api::rest::users::get_borrowed_positions
    ),
    components(
        schemas(
            HealthResponse,
            MarketStats,
            Asset,
            UserPortfolio,
            UserAsset,
            HealthInfo,
            Transaction,
            SupplyRequest,
            BorrowRequest,
            SuppliedPosition,
            BorrowedPosition
        )
    ),
    tags(
        (name = "Health", description = "Health check endpoints"),
        (name = "Market", description = "Market data endpoints"),
        (name = "Users", description = "User-specific endpoints"),
        (name = "D3FI API", description = "API pour la plateforme D3FI")
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