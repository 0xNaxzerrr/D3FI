use serde::{Serialize, Deserialize};
use sqlx::FromRow;
use sqlx::types::BigDecimal;
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Asset {
    pub id: Uuid,
    pub symbol: String,
    pub name: String,
    #[serde(with = "bigdecimal_serde")]
    pub price: BigDecimal,
    pub updated_at: Option<DateTime<Utc>>,
}

mod bigdecimal_serde {
    use serde::{self, Deserialize, Deserializer, Serializer};
    use sqlx::types::BigDecimal;

    pub fn serialize<S>(decimal: &BigDecimal, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&decimal.to_string())
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<BigDecimal, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        s.parse().map_err(serde::de::Error::custom)
    }
}