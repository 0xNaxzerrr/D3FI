pub mod models;
pub mod postgres;

use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;
use anyhow::Result;

pub async fn init_db_pool(database_url: &str) -> Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .acquire_timeout(Duration::from_secs(3))
        .connect(database_url)
        .await?;
    
    Ok(pool)
}