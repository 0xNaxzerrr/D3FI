use crate::api::models::{HealthInfo, Transaction, UserAsset, UserPortfolio};
use crate::api::state::AppState;
use crate::db::models::{BorrowedPosition, SuppliedPosition};
use crate::db::postgres::{AssetRepository, PositionRepository, UserRepository};
use anyhow::Result;
use axum::{
    extract::{Json as ExtractJson, Path, State},
    routing::{get, post},
    Json, Router,
};
use sqlx::types::BigDecimal;
use std::str::FromStr;
use utoipa::ToSchema;

// Structs pour les requêtes
#[derive(serde::Deserialize, ToSchema)]
pub struct SupplyRequest {
    /// Symbole de l'actif à fournir (ex: "ETH", "USDC")
    pub asset_symbol: String,
    /// Montant à fournir, sous forme de chaîne de caractères (ex: "10.5")
    pub amount: String,
    /// Indique si cet actif sera utilisé comme collatéral
    pub collateral: bool,
}

#[derive(serde::Deserialize, ToSchema)]
pub struct BorrowRequest {
    /// Symbole de l'actif à emprunter (ex: "ETH", "USDC")
    pub asset_symbol: String,
    /// Montant à emprunter, sous forme de chaîne de caractères (ex: "5.0")
    pub amount: String,
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/api/v1/users/:address/portfolio", get(get_user_portfolio))
        .route("/api/v1/users/:address/health", get(get_user_health))
        .route("/api/v1/users/:address/history", get(get_user_history))
        .route(
            "/api/v1/users/:address/health/current",
            get(get_user_current_health),
        )
        .route(
            "/api/v1/users/:address/health/history",
            get(get_user_health_history),
        )
        // Nouvelles routes
        .route("/api/v1/users/:address/supply", post(supply_asset))
        .route("/api/v1/users/:address/borrow", post(borrow_asset))
        .route(
            "/api/v1/users/:address/supplied-positions",
            get(get_supplied_positions),
        )
        .route(
            "/api/v1/users/:address/borrowed-positions",
            get(get_borrowed_positions),
        )
        .route("/users/positions", get(get_user_positions))
        .with_state(state)
}

/// Get user's portfolio information
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/portfolio",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User portfolio retrieved successfully", body = UserPortfolio)
    )
)]
pub async fn get_user_portfolio(Path(address): Path<String>) -> Json<UserPortfolio> {
    Json(UserPortfolio {
        address,
        supplied_assets: vec![UserAsset {
            symbol: "ETH".to_string(),
            amount: "10.5".to_string(),
            value_usd: "25000.00".to_string(),
        }],
        borrowed_assets: vec![UserAsset {
            symbol: "USDC".to_string(),
            amount: "15000".to_string(),
            value_usd: "15000.00".to_string(),
        }],
        health_factor: "1.8".to_string(),
    })
}

/// Get user's health information
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/health",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User health information retrieved successfully", body = HealthInfo)
    )
)]
pub async fn get_user_health(Path(_address): Path<String>) -> Json<HealthInfo> {
    Json(HealthInfo {
        current: "1.8".to_string(),
        threshold: "1.0".to_string(),
        status: "safe".to_string(),
    })
}

/// Get user's transaction history
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/history",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User transaction history retrieved successfully", body = Vec<Transaction>)
    )
)]
pub async fn get_user_history(Path(_address): Path<String>) -> Json<Vec<Transaction>> {
    Json(vec![
        Transaction {
            timestamp: 1680000000,
            tx_hash: "0x...".to_string(),
            action: "Supply".to_string(),
            asset: "ETH".to_string(),
            amount: "5.0".to_string(),
        },
        Transaction {
            timestamp: 1680100000,
            tx_hash: "0x...".to_string(),
            action: "Borrow".to_string(),
            asset: "USDC".to_string(),
            amount: "10000".to_string(),
        },
    ])
}

/// Get user's current health factor
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/health/current",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User current health factor retrieved successfully", body = String)
    )
)]
pub async fn get_user_current_health(Path(_address): Path<String>) -> Json<String> {
    Json("1.8".to_string())
}

/// Get user's health factor history
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/health/history",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User health factor history retrieved successfully", body = Vec<(u64, String)>)
    )
)]
pub async fn get_user_health_history(Path(_address): Path<String>) -> Json<Vec<(u64, String)>> {
    Json(vec![
        (1680000000, "2.1".to_string()),
        (1680100000, "1.9".to_string()),
        (1680200000, "1.8".to_string()),
    ])
}

/// Supply an asset
#[utoipa::path(
    post,
    path = "/api/v1/users/{address}/supply",
    request_body = SupplyRequest,
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 201, description = "Asset supplied successfully", body = SuppliedPosition),
        (status = 400, description = "Invalid request"),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn supply_asset(
    State(state): State<AppState>,
    Path(address): Path<String>,
    ExtractJson(request): ExtractJson<SupplyRequest>,
) -> Result<Json<SuppliedPosition>, axum::http::StatusCode> {
    // Vérifier que l'asset existe
    let asset_repo = AssetRepository::new(state.db.clone());
    let asset = asset_repo
        .get_asset_by_symbol(&request.asset_symbol)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {:?}", e);
            axum::http::StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(axum::http::StatusCode::NOT_FOUND)?;

    // Vérifier que l'utilisateur existe ou le créer
    let user_repo = UserRepository::new(state.db.clone());
    if user_repo
        .get_user_by_address(&address)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {:?}", e);
            axum::http::StatusCode::INTERNAL_SERVER_ERROR
        })?
        .is_none()
    {
        user_repo
            .create_user(&address, None, None)
            .await
            .map_err(|e| {
                tracing::error!("Failed to create user: {:?}", e);
                axum::http::StatusCode::INTERNAL_SERVER_ERROR
            })?;
    }

    // Convertir le montant en BigDecimal
    let amount =
        BigDecimal::from_str(&request.amount).map_err(|_| axum::http::StatusCode::BAD_REQUEST)?;

    // Créer la position
    let position_repo = PositionRepository::new(state.db);
    let position = position_repo
        .create_supplied_position(&address, asset.id, amount, request.collateral)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create supplied position: {:?}", e);
            axum::http::StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(Json(position))
}

/// Borrow an asset
#[utoipa::path(
    post,
    path = "/api/v1/users/{address}/borrow",
    request_body = BorrowRequest,
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 201, description = "Asset borrowed successfully", body = BorrowedPosition),
        (status = 400, description = "Invalid request"),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn borrow_asset(
    State(state): State<AppState>,
    Path(address): Path<String>,
    ExtractJson(request): ExtractJson<BorrowRequest>,
) -> Result<Json<BorrowedPosition>, axum::http::StatusCode> {
    // Vérifier que l'asset existe
    let asset_repo = AssetRepository::new(state.db.clone());
    let asset = asset_repo
        .get_asset_by_symbol(&request.asset_symbol)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {:?}", e);
            axum::http::StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(axum::http::StatusCode::NOT_FOUND)?;

    // Vérifier que l'utilisateur existe
    let user_repo = UserRepository::new(state.db.clone());
    if user_repo
        .get_user_by_address(&address)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {:?}", e);
            axum::http::StatusCode::INTERNAL_SERVER_ERROR
        })?
        .is_none()
    {
        return Err(axum::http::StatusCode::NOT_FOUND);
    }

    // Convertir le montant en BigDecimal
    let amount =
        BigDecimal::from_str(&request.amount).map_err(|_| axum::http::StatusCode::BAD_REQUEST)?;

    // Créer la position d'emprunt
    let position_repo = PositionRepository::new(state.db);
    let position = position_repo
        .create_borrowed_position(&address, asset.id, amount)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create borrowed position: {:?}", e);
            axum::http::StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(Json(position))
}

/// Get user's supplied positions
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/supplied-positions",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User supplied positions retrieved successfully", body = Vec<SuppliedPosition>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_supplied_positions(
    State(state): State<AppState>,
    Path(address): Path<String>,
) -> Result<Json<Vec<SuppliedPosition>>, axum::http::StatusCode> {
    let position_repo = PositionRepository::new(state.db);

    match position_repo.get_user_supplied_positions(&address).await {
        Ok(positions) => Ok(Json(positions)),
        Err(e) => {
            tracing::error!("Failed to get supplied positions: {:?}", e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Get user's borrowed positions
#[utoipa::path(
    get,
    path = "/api/v1/users/{address}/borrowed-positions",
    tag = "Users",
    params(
        ("address" = String, Path, description = "Ethereum address of the user")
    ),
    responses(
        (status = 200, description = "User borrowed positions retrieved successfully", body = Vec<BorrowedPosition>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn get_borrowed_positions(
    State(state): State<AppState>,
    Path(address): Path<String>,
) -> Result<Json<Vec<BorrowedPosition>>, axum::http::StatusCode> {
    let position_repo = PositionRepository::new(state.db);

    match position_repo.get_user_borrowed_positions(&address).await {
        Ok(positions) => Ok(Json(positions)),
        Err(e) => {
            tracing::error!("Failed to get borrowed positions: {:?}", e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

async fn get_user_positions(_state: State<AppState>) -> axum::Json<serde_json::Value> {
    // Pour l'instant, retourner une réponse vide
    axum::Json(serde_json::json!({
        "positions": []
    }))
}
