use serde::{Serialize, Deserialize};
use sqlx::FromRow;
use sqlx::types::BigDecimal;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use utoipa::ToSchema;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
#[serde(rename_all = "camelCase")]
pub struct SuppliedPosition {
    /// Identifiant unique de la position
    pub id: Uuid,
    /// Adresse ethereum de l'utilisateur
    pub user_address: String,
    /// Identifiant de l'actif fourni
    pub asset_id: Uuid,
    /// Montant fourni
    #[serde(with = "bigdecimal_serde")]
    #[schema(value_type = String, example = "10.5")]
    pub amount: BigDecimal,
    /// Indique si cette position est utilisée comme collatéral
    pub collateral: bool,
    /// Date de création de la position
    #[schema(value_type = Option<String>, example = "2025-05-01T12:00:00Z")]
    pub created_at: Option<DateTime<Utc>>,
    /// Date de dernière mise à jour de la position
    #[schema(value_type = Option<String>, example = "2025-05-01T12:00:00Z")]
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
#[serde(rename_all = "camelCase")]
pub struct BorrowedPosition {
    /// Identifiant unique de la position
    pub id: Uuid,
    /// Adresse ethereum de l'utilisateur
    pub user_address: String,
    /// Identifiant de l'actif emprunté
    pub asset_id: Uuid,
    /// Montant emprunté
    #[serde(with = "bigdecimal_serde")]
    #[schema(value_type = String, example = "5.0")]
    pub amount: BigDecimal,
    /// Date de création de la position
    #[schema(value_type = Option<String>, example = "2025-05-01T12:00:00Z")]
    pub created_at: Option<DateTime<Utc>>,
    /// Date de dernière mise à jour de la position
    #[schema(value_type = Option<String>, example = "2025-05-01T12:00:00Z")]
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
#[serde(rename_all = "camelCase")]
pub struct HealthFactorHistory {
    /// Identifiant unique de l'entrée d'historique
    pub id: Uuid,
    /// Adresse ethereum de l'utilisateur
    pub user_address: String,
    /// Valeur du health factor
    #[serde(with = "bigdecimal_serde")]
    #[schema(value_type = String, example = "1.8")]
    pub health_factor: BigDecimal,
    /// Horodatage de l'entrée
    #[schema(value_type = Option<String>, example = "2025-05-01T12:00:00Z")]
    pub timestamp: Option<DateTime<Utc>>,
}

// Réutilisons le même serde que asset.rs
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