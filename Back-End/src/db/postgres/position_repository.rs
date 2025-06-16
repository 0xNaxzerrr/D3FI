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
            WHERE user_address = $1 AND liquidated = false
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
        // D'abord vérifier si une position liquidée existe
        let existing = sqlx::query!(
            r#"
            SELECT id, liquidated 
            FROM supplied_positions
            WHERE user_address = $1 AND asset_id = $2
            "#,
            user_address,
            asset_id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        let position = match existing {
            // Si une position existe et est liquidée, créer une nouvelle position
            Some(row) if row.liquidated => {
                sqlx::query_as!(
                    SuppliedPosition,
                    r#"
                    INSERT INTO supplied_positions (user_address, asset_id, amount, collateral)
                    VALUES ($1, $2, $3, $4)
                    RETURNING *
                    "#,
                    user_address,
                    asset_id,
                    amount,
                    collateral
                )
                .fetch_one(&self.pool)
                .await?
            },
            // Si une position existe et n'est pas liquidée, mettre à jour
            Some(_) => {
                sqlx::query_as!(
                    SuppliedPosition,
                    r#"
                    UPDATE supplied_positions
                    SET amount = supplied_positions.amount + $3,
                        collateral = $4,
                        updated_at = now()
                    WHERE user_address = $1 AND asset_id = $2 AND liquidated = false
                    RETURNING *
                    "#,
                    user_address,
                    asset_id,
                    amount,
                    collateral
                )
                .fetch_one(&self.pool)
                .await?
            },
            // Si aucune position n'existe, en créer une nouvelle
            None => {
                sqlx::query_as!(
                    SuppliedPosition,
                    r#"
                    INSERT INTO supplied_positions (user_address, asset_id, amount, collateral)
                    VALUES ($1, $2, $3, $4)
                    RETURNING *
                    "#,
                    user_address,
                    asset_id,
                    amount,
                    collateral
                )
                .fetch_one(&self.pool)
                .await?
            }
        };

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
            WHERE user_address = $1 AND liquidated = false
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
        // D'abord vérifier si une position liquidée existe
        let existing = sqlx::query!(
            r#"
            SELECT id, liquidated 
            FROM borrowed_positions
            WHERE user_address = $1 AND asset_id = $2
            "#,
            user_address,
            asset_id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        let position = match existing {
            // Si une position existe et est liquidée, créer une nouvelle position
            Some(row) if row.liquidated => {
                sqlx::query_as!(
                    BorrowedPosition,
                    r#"
                    INSERT INTO borrowed_positions (user_address, asset_id, amount)
                    VALUES ($1, $2, $3)
                    RETURNING *
                    "#,
                    user_address,
                    asset_id,
                    amount
                )
                .fetch_one(&self.pool)
                .await?
            },
            // Si une position existe et n'est pas liquidée, mettre à jour
            Some(_) => {
                sqlx::query_as!(
                    BorrowedPosition,
                    r#"
                    UPDATE borrowed_positions
                    SET amount = borrowed_positions.amount + $3,
                        updated_at = now()
                    WHERE user_address = $1 AND asset_id = $2 AND liquidated = false
                    RETURNING *
                    "#,
                    user_address,
                    asset_id,
                    amount
                )
                .fetch_one(&self.pool)
                .await?
            },
            // Si aucune position n'existe, en créer une nouvelle
            None => {
                sqlx::query_as!(
                    BorrowedPosition,
                    r#"
                    INSERT INTO borrowed_positions (user_address, asset_id, amount)
                    VALUES ($1, $2, $3)
                    RETURNING *
                    "#,
                    user_address,
                    asset_id,
                    amount
                )
                .fetch_one(&self.pool)
                .await?
            }
        };

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

    // Récupérer tous les utilisateurs qui ont des positions ACTIVES (non liquidées)
    pub async fn get_all_users_with_positions(&self) -> Result<Vec<String>> {
        // Récupérer les adresses des utilisateurs avec des positions fournies ACTIVES
        let supplied_users = sqlx::query!(
            r#"
            SELECT DISTINCT user_address 
            FROM supplied_positions
            WHERE liquidated = false
            "#
        )
        .fetch_all(&self.pool)
        .await?
        .into_iter()
        .map(|row| row.user_address)
        .collect::<Vec<String>>();

        // Récupérer les adresses des utilisateurs avec des positions empruntées ACTIVES
        let borrowed_users = sqlx::query!(
            r#"
            SELECT DISTINCT user_address 
            FROM borrowed_positions
            WHERE liquidated = false
            "#
        )
        .fetch_all(&self.pool)
        .await?
        .into_iter()
        .map(|row| row.user_address)
        .collect::<Vec<String>>();

        // Combiner les deux listes et éliminer les doublons
        let mut all_users = Vec::new();
        
        for user in supplied_users {
            if !all_users.contains(&user) {
                all_users.push(user);
            }
        }
        
        for user in borrowed_users {
            if !all_users.contains(&user) {
                all_users.push(user);
            }
        }
        
        Ok(all_users)
    }

    // Méthode pour marquer toutes les positions d'un utilisateur comme liquidées
    pub async fn mark_user_positions_as_liquidated(&self, address: &str) -> Result<()> {
        // Marquer les positions fournies comme liquidées (saisies par la plateforme)
        sqlx::query!(
            r#"
            UPDATE supplied_positions
            SET liquidated = true, updated_at = now()
            WHERE user_address = $1 AND liquidated = false
            "#,
            address
        )
        .execute(&self.pool)
        .await?;

        // Supprimer les positions empruntées (dette soldée par la saisie du collatéral)
        sqlx::query!(
            r#"
            DELETE FROM borrowed_positions
            WHERE user_address = $1 AND liquidated = false
            "#,
            address
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    // Méthode pour vérifier si un utilisateur a déjà été liquidé
    pub async fn has_been_liquidated(&self, address: &str) -> Result<bool> {
        // Vérifier s'il existe des positions liquidées pour cet utilisateur
        let result = sqlx::query!(
            r#"
            SELECT COUNT(*) as count
            FROM (
                SELECT user_address FROM supplied_positions WHERE user_address = $1 AND liquidated = true
                UNION
                SELECT user_address FROM borrowed_positions WHERE user_address = $1 AND liquidated = true
            ) as liquidated_positions
            "#,
            address
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(result.count.unwrap_or(0) > 0)
    }

    // Méthode pour vérifier si un utilisateur a encore des positions actives (non liquidées)
    pub async fn has_active_positions(&self, address: &str) -> Result<bool> {
        // Vérifier s'il existe des positions actives (non liquidées) pour cet utilisateur
        let result = sqlx::query!(
            r#"
            SELECT COUNT(*) as count
            FROM (
                SELECT user_address FROM supplied_positions WHERE user_address = $1 AND liquidated = false
                UNION
                SELECT user_address FROM borrowed_positions WHERE user_address = $1 AND liquidated = false
            ) as active_positions
            "#,
            address
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(result.count.unwrap_or(0) > 0)
    }
} 