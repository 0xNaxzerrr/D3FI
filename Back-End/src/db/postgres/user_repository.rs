use anyhow::Result;
use sqlx::PgPool;
use crate::db::models::User;

pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn get_user_by_address(&self, address: &str) -> Result<Option<User>> {
        let user = sqlx::query_as!(
            User,
            "SELECT * FROM users WHERE address = $1",
            address
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn create_user(&self, address: &str, username: Option<&str>, email: Option<&str>) -> Result<User> {
        let user = sqlx::query_as!(
            User,
            r#"
            INSERT INTO users (address, username, email)
            VALUES ($1, $2, $3)
            RETURNING *
            "#,
            address,
            username,
            email
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn get_all_users(&self) -> Result<Vec<User>> {
        let users = sqlx::query_as!(
            User,
            "SELECT * FROM users ORDER BY created_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(users)
    }
} 