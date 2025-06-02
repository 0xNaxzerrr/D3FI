use anyhow::Result;
use sqlx::PgPool;
use sqlx::types::BigDecimal;
use uuid::Uuid;
use crate::db::models::{SuppliedPosition, BorrowedPosition, HealthFactorHistory};

pub struct PositionRepository {
    pool: PgPool,
}

impl PositionRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    // Méthodes pour les positions de prêt (supply)
    pub async fn get_user_supplied_positions(&self, address: &str) -> Result<Vec<SuppliedPosition>> {
        let positions = sqlx::query_as!(
            SuppliedPosition,
            r#"
            SELECT * FROM supplied_positions 
            WHERE user_address = $1
            "#,
            address
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(positions)
    }

    pub async fn create_supplied_position(
        &self, 
        user_address: &str, 
        asset_id: Uuid, 
        amount: BigDecimal,
        collateral: bool
    ) -> Result<SuppliedPosition> {
        let position = sqlx::query_as!(
            SuppliedPosition,
            r#"
            INSERT INTO supplied_positions (user_address, asset_id, amount, collateral)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (user_address, asset_id) 
            DO UPDATE SET amount = supplied_positions.amount + EXCLUDED.amount,
                          collateral = EXCLUDED.collateral,
                          updated_at = now()
            RETURNING *
            "#,
            user_address,
            asset_id,
            amount,
            collateral
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(position)
    }

    pub async fn update_supplied_position(
        &self, 
        id: Uuid, 
        amount: BigDecimal,
        collateral: bool
    ) -> Result<SuppliedPosition> {
        let position = sqlx::query_as!(
            SuppliedPosition,
            r#"
            UPDATE supplied_positions 
            SET amount = $2, collateral = $3, updated_at = now()
            WHERE id = $1
            RETURNING *
            "#,
            id,
            amount,
            collateral
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(position)
    }

    // Méthodes pour les positions d'emprunt (borrow)
    pub async fn get_user_borrowed_positions(&self, address: &str) -> Result<Vec<BorrowedPosition>> {
        let positions = sqlx::query_as!(
            BorrowedPosition,
            r#"
            SELECT * FROM borrowed_positions 
            WHERE user_address = $1
            "#,
            address
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(positions)
    }

    pub async fn create_borrowed_position(
        &self, 
        user_address: &str, 
        asset_id: Uuid, 
        amount: BigDecimal
    ) -> Result<BorrowedPosition> {
        let position = sqlx::query_as!(
            BorrowedPosition,
            r#"
            INSERT INTO borrowed_positions (user_address, asset_id, amount)
            VALUES ($1, $2, $3)
            ON CONFLICT (user_address, asset_id) 
            DO UPDATE SET amount = borrowed_positions.amount + EXCLUDED.amount,
                          updated_at = now()
            RETURNING *
            "#,
            user_address,
            asset_id,
            amount
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(position)
    }

    pub async fn update_borrowed_position(
        &self, 
        id: Uuid, 
        amount: BigDecimal
    ) -> Result<BorrowedPosition> {
        let position = sqlx::query_as!(
            BorrowedPosition,
            r#"
            UPDATE borrowed_positions 
            SET amount = $2, updated_at = now()
            WHERE id = $1
            RETURNING *
            "#,
            id,
            amount
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(position)
    }

    // Méthodes pour l'historique du health factor
    pub async fn save_health_factor(
        &self,
        user_address: &str,
        health_factor: BigDecimal
    ) -> Result<HealthFactorHistory> {
        let history = sqlx::query_as!(
            HealthFactorHistory,
            r#"
            INSERT INTO health_factor_history (user_address, health_factor)
            VALUES ($1, $2)
            RETURNING *
            "#,
            user_address,
            health_factor
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(history)
    }

    pub async fn get_health_factor_history(
        &self,
        user_address: &str,
        limit: i64
    ) -> Result<Vec<HealthFactorHistory>> {
        let history = sqlx::query_as!(
            HealthFactorHistory,
            r#"
            SELECT * FROM health_factor_history
            WHERE user_address = $1
            ORDER BY timestamp DESC
            LIMIT $2
            "#,
            user_address,
            limit
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(history)
    }
} 