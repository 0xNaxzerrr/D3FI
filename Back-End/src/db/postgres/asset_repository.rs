use anyhow::Result;
use sqlx::PgPool;
use crate::db::models::Asset;

pub struct AssetRepository {
    pool: PgPool,
}

impl AssetRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn get_all_assets(&self) -> Result<Vec<Asset>> {
        let assets = sqlx::query_as!(
            Asset,
            "SELECT * FROM assets ORDER BY symbol"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(assets)
    }

    pub async fn get_asset_by_symbol(&self, symbol: &str) -> Result<Option<Asset>> {
        let asset = sqlx::query_as!(
            Asset,
            "SELECT * FROM assets WHERE symbol = $1",
            symbol
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(asset)
    }
}