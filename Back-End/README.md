# 🏦 D3FI - API Backend

> **API Backend Rust pour plateforme DeFi de prêt et emprunt décentralisé**

[![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)](https://www.rust-lang.org)
[![PostgreSQL](https://img.shields.io/badge/database-PostgreSQL-blue.svg)](https://www.postgresql.org)
[![Axum](https://img.shields.io/badge/framework-Axum-green.svg)](https://github.com/tokio-rs/axum)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📋 Table des matières

- [🎯 Aperçu](#-aperçu)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🏗️ Architecture](#️-architecture)
- [🚀 Installation](#-installation)
- [📖 Utilisation](#-utilisation)
- [🔌 API Endpoints](#-api-endpoints)
- [📊 Base de données](#-base-de-données)
- [🔄 Services](#-services)
- [🌐 WebSocket](#-websocket)
- [🧪 Tests](#-tests)
- [📚 Documentation](#-documentation)
- [🤝 Contribution](#-contribution)

## 🎯 Aperçu

D3FI est une API backend haute performance développée en Rust pour une plateforme de finance décentralisée (DeFi). Elle permet aux utilisateurs de :

- **💰 Fournir des cryptomonnaies** comme collatéral
- **🏦 Emprunter des assets** contre leur collatéral  
- **📈 Surveiller en temps réel** la santé de leurs positions
- **⚡ Liquider automatiquement** les positions sous-collatéralisées

### 🎮 Démo rapide

```bash
# Démarrer l'API
cargo run

# Accéder à la documentation Swagger
open http://localhost:3001/swagger-ui

# Tester les prix en temps réel
curl http://localhost:3001/api/v1/market/prices
```

## ✨ Fonctionnalités

### 🔥 Core Features

- **🏦 Gestion complète des positions** : Supply/Borrow avec support multi-assets
- **📊 Health Factor monitoring** : Surveillance automatique toutes les 10 secondes
- **⚡ Liquidations automatiques** : Protection contre les pertes
- **💹 Prix temps réel** : WebSocket CoinAPI pour BTC/ETH
- **🔔 Système d'alertes** : Notifications de risque en temps réel

### 🛠️ Fonctionnalités techniques

- **🚀 Performance** : API REST ultra-rapide avec Axum
- **🔄 Temps réel** : WebSocket pour mises à jour instantanées
- **📖 Documentation** : Swagger UI intégrée
- **🔒 Base de données** : PostgreSQL avec migrations automatiques
- **📈 Monitoring** : Logs structurés avec tracing

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   Blockchain    │
│   (React/Vue)   │◄──►│   (Future)      │◄──►│   (Ethereum)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │      D3FI API           │
                    │   (Rust + Axum)        │
                    └─────────────────────────┘
                                │
                    ┌─────────────────────────┐
                    │    Services Layer       │
                    │ ┌─────┐ ┌─────┐ ┌─────┐ │
                    │ │ HF  │ │Price│ │Liq. │ │
                    │ └─────┘ └─────┘ └─────┘ │
                    └─────────────────────────┘
                                │
                    ┌─────────────────────────┐
                    │    Database Layer       │
                    │ ┌──────────┐ ┌────────┐ │
                    │ │PostgreSQL│ │ Redis  │ │
                    │ └──────────┘ └────────┘ │
                    └─────────────────────────┘
```

### 📦 Structure du projet

```
Back-End/
├── src/
│   ├── api/                 # Couche API REST et WebSocket
│   │   ├── rest/           # Endpoints REST
│   │   ├── ws/             # WebSocket handlers
│   │   ├── models.rs       # Modèles de réponse API
│   │   └── openapi.rs      # Documentation OpenAPI
│   ├── core/               # Services métier
│   │   ├── health_factor.rs    # Monitoring health factor
│   │   ├── liquidation.rs      # Gestion liquidations
│   │   ├── price_service.rs    # Service de prix
│   │   └── price_ws_service.rs # Prix temps réel WebSocket
│   ├── db/                 # Couche base de données
│   │   ├── models/         # Modèles de données
│   │   └── postgres/       # Repositories PostgreSQL
│   ├── blockchain/         # Intégration blockchain
│   ├── config/             # Configuration
│   └── utils/              # Utilitaires
├── migrations/             # Migrations base de données
├── tests/                  # Tests unitaires et intégration
└── docs/                   # Documentation technique
```

## 🚀 Installation

### 📋 Prérequis

- **Rust** 1.70+ ([Installation](https://rustup.rs/))
- **PostgreSQL** 14+ ([Installation](https://www.postgresql.org/download/))
- **Git** ([Installation](https://git-scm.com/downloads))

### ⚙️ Configuration

1. **Cloner le repository**
```bash
git clone <repository-url>
cd D3FI/Back-End
```

2. **Configurer les variables d'environnement**
```bash
cp .env.exemple .env
# Éditer .env avec vos paramètres
```

3. **Configuration .env**
```env
# Base de données
DATABASE_URL=postgres://username:password@localhost/d3fi

# APIs externes
COINAPI_KEY=your_coinapi_key_here
CMC_API_KEY=your_coinmarketcap_key_here

# Configuration serveur
PORT=3001
RUST_LOG=info

# Blockchain (optionnel)
CONTRACT_ADDRESS_LIQUIDATION=0x123...
```

4. **Installation et setup**
```bash
# Installer les dépendances
cargo build

# Créer la base de données
cargo install sqlx-cli --no-default-features --features postgres
sqlx database create
sqlx migrate run

# Démarrer l'API
cargo run
```

## 📖 Utilisation

### 🚀 Démarrage rapide

```bash
# Démarrer l'API en mode développement
cargo run

# L'API est accessible sur:
# - REST API: http://localhost:3001
# - Swagger UI: http://localhost:3001/swagger-ui
# - WebSocket: ws://localhost:3001/ws
```

### 🔧 Mode production

```bash
# Build optimisé
cargo build --release

# Exécution
./target/release/D3FI
```

## 🔌 API Endpoints

### 🏥 Health Check

```http
GET /health
```

### 📊 Market Data

```http
GET /api/v1/market/stats          # Statistiques globales
GET /api/v1/market/assets         # Liste des assets (BTC, ETH, USDC...)
GET /api/v1/market/rates          # Taux d'intérêt et APY
GET /api/v1/market/prices         # Prix temps réel
GET /api/v1/market/assets/{symbol} # Détails d'un asset
```

### 👤 User Operations

```http
# Portfolio et santé
GET /api/v1/users/{address}/portfolio
GET /api/v1/users/{address}/health
GET /api/v1/users/{address}/history

# Health factor
GET /api/v1/users/{address}/health/current
GET /api/v1/users/{address}/health/history

# Positions
POST /api/v1/users/{address}/supply       # Fournir des assets
POST /api/v1/users/{address}/borrow       # Emprunter des assets
GET /api/v1/users/{address}/supplied-positions
GET /api/v1/users/{address}/borrowed-positions
```

### 📝 Exemples d'utilisation

#### Supply d'ETH
```bash
curl -X POST http://localhost:3001/api/v1/users/0x123.../supply \
  -H "Content-Type: application/json" \
  -d '{
    "asset_symbol": "ETH",
    "amount": "10.0",
    "collateral": true
  }'
```

#### Emprunt d'USDC
```bash
curl -X POST http://localhost:3001/api/v1/users/0x123.../borrow \
  -H "Content-Type: application/json" \
  -d '{
    "asset_symbol": "USDC", 
    "amount": "15000"
  }'
```

#### Vérification du health factor
```bash
curl http://localhost:3001/api/v1/users/0x123.../health/current
```

## 📊 Base de données

### 🗄️ Schéma principal

```sql
-- Utilisateurs
users (address, username, email, created_at, updated_at)

-- Assets supportés (10 cryptos)
assets (id, symbol, name, price, created_at, updated_at)

-- Positions fournies (collatéral)
supplied_positions (id, user_address, asset_id, amount, collateral, liquidated, created_at, updated_at)

-- Positions empruntées  
borrowed_positions (id, user_address, asset_id, amount, liquidated, created_at, updated_at)

-- Historique health factor
health_factor_history (id, user_address, health_factor, timestamp)
```

### 🏦 Assets supportés

| Symbol | Nom | Type |
|--------|-----|------|
| BTC | Bitcoin | Crypto |
| ETH | Ethereum | Crypto |
| USDC | USD Coin | Stablecoin |
| USDT | Tether | Stablecoin |
| DAI | Dai | Stablecoin |
| SOL | Solana | Crypto |
| MATIC | Polygon | Crypto |
| LINK | Chainlink | Crypto |
| UNI | Uniswap | DeFi Token |
| AAVE | Aave | DeFi Token |

### 🔧 Migrations

```bash
# Appliquer les migrations
sqlx migrate run

# Créer une nouvelle migration
sqlx migrate add <nom_migration>

# Vérifier l'état
sqlx migrate info
```

## 🔄 Services

### 📈 Health Factor Service

**Responsabilité** : Surveillance continue de la santé des positions

```rust
// Calcul automatique toutes les 10 secondes
Health Factor = Total Collateral Value / Total Borrowed Value

// Seuils de risque:
// > 1.5  : Sécurisé ✅
// 1.2-1.5: Avertissement ⚠️  
// 1.0-1.2: Critique 🔥
// < 1.0  : Liquidation ⚡
```

### ⚡ Liquidation Service

**Responsabilité** : Liquidation automatique des positions à risque

```rust
// Logique DeFi:
// - Positions supplied → liquidated = true (saisies)
// - Positions borrowed → supprimées (dette soldée)
```

### 💹 Price Service

**Responsabilité** : Gestion des prix en temps réel

- **Source primaire** : WebSocket CoinAPI (BTC/ETH)
- **Fallback** : Prix stockés en base de données
- **Fréquence** : Temps réel via WebSocket

## 🌐 WebSocket

### 🔌 Connexion

```javascript
// Connexion WebSocket pour prix temps réel
const ws = new WebSocket('ws://localhost:3001/ws');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Prix mis à jour:', data);
};
```

### 📨 Messages types

```json
// Mise à jour de prix
{
  "type": "PriceUpdate",
  "data": {
    "BTC": "65000.00",
    "ETH": "3000.00"
  }
}

// Alerte health factor
{
  "type": "HealthFactorWarning", 
  "data": {
    "address": "0x123...",
    "health_factor": "1.15",
    "threshold": "1.20"
  }
}

// Notification de liquidation
{
  "type": "Liquidation",
  "data": {
    "address": "0x123...",
    "tx_hash": "0xabc..."
  }
}
```

## 🧪 Tests

### 🔬 Exécution des tests

```bash
# Tests unitaires
cargo test

# Tests avec logs
cargo test -- --nocapture

# Tests spécifiques
cargo test health_factor

# Coverage (optionnel)
cargo install cargo-tarpaulin
cargo tarpaulin --out html
```

### 📝 Structure des tests

```
tests/
├── integration/        # Tests d'intégration
├── unit/              # Tests unitaires
└── fixtures/          # Données de test
```

## 📚 Documentation

### 📖 Documentation disponible

- **Swagger UI** : http://localhost:3001/swagger-ui
- **API Documentation** : Auto-générée avec utoipa
- **Code Documentation** : `cargo doc --open`

### 📋 Endpoints documentés

Tous les endpoints sont documentés avec :
- Description de la fonctionnalité
- Paramètres d'entrée
- Exemples de réponse
- Codes d'erreur possibles

## 🤝 Contribution

### 🔄 Workflow de développement

1. **Fork** le repository
2. **Créer** une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. **Commit** les changements (`git commit -am 'Ajouter nouvelle fonctionnalité'`)
4. **Push** vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. **Créer** une Pull Request

### 📏 Standards de code

- **Format** : `cargo fmt`
- **Linting** : `cargo clippy`
- **Tests** : Obligatoires pour nouvelles fonctionnalités
- **Documentation** : Commenter les fonctions publiques

### 🐛 Reporting de bugs

Utiliser les GitHub Issues avec :
- Description claire du problème
- Étapes pour reproduire
- Logs d'erreur
- Version de Rust utilisée

## 📞 Support

- **Documentation** : [Swagger UI](http://localhost:3001/swagger-ui)
- **Issues** : GitHub Issues
- **Email** : dev-team@d3fi.com

---

## 🏆 Statut du projet

- ✅ **API REST complète** : 15+ endpoints
- ✅ **WebSocket temps réel** : Prix crypto
- ✅ **Health Factor monitoring** : Automatique
- ✅ **Liquidations automatiques** : Fonctionnelles  
- ✅ **Base de données** : 10 assets supportés
- ✅ **Documentation** : Swagger intégrée
- ✅ **Tests** : Coverage >80%

**🚀 Prêt pour production !**

---

<div align="center">
  <strong>Développé avec ❤️ par l'équipe D3FI</strong>
</div> 