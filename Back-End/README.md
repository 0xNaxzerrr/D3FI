# D3FI API - Backend Rust

API backend pour la plateforme D3FI développée en Rust avec Axum.

## �� Démarrage rapide

```bash
# 1. Cloner le projet
git clone <votre-repo>
cd D3FI/Back-End

# 2. Démarrer l'environnement (PostgreSQL + Redis)
./dev-start.sh

# 3. Dans un nouveau terminal, démarrer l'API
cargo run
```

✅ L'API sera disponible sur **http://localhost:8080**  
📚 Documentation Swagger : **http://localhost:8080/docs**

## 🏗️ Architecture

- **Framework** : Axum (Rust)
- **Base de données** : PostgreSQL
- **Cache** : Redis  
- **ORM** : SQLx

## 🛑 Arrêter les services

```bash
docker-compose down
```

## 📋 Prérequis

- [Rust](https://rustup.rs/) installé
- [Docker](https://docs.docker.com/get-docker/) installé

## 📊 Services

- **Health** : Vérification de l'état de l'API
- **Market Data** : Données de marché et prix
- **User Management** : Gestion des utilisateurs
- **Positions** : Gestion des positions DeFi
- **Liquidation** : Service de liquidation automatique
- **WebSocket** : Mises à jour en temps réel

## 🔧 Développement

```bash
# Tests
cargo test

# Format du code
cargo fmt

# Linting
cargo clippy
```

## 📝 Variables d'environnement

Voir le fichier `env.example` pour la configuration complète. 