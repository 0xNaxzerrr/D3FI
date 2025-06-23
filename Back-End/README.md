# D3FI API - Backend Rust

API backend pour la plateforme D3FI développée en Rust avec Axum.

## 🚀 Démarrage rapide

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

## 🚨 Troubleshooting

### L'API ne fonctionne pas sur d'autres machines

🎯 **Diagnostic automatique** :
```bash
./check-network.sh
```

Si l'API fonctionne sur votre machine mais pas sur d'autres :

1. **Vérifiez le fichier `.env`** :
   ```bash
   # Dans .env, assurez-vous d'avoir :
   API_HOST=0.0.0.0  # ❌ PAS 127.0.0.1
   API_PORT=8080
   ```

2. **Testez l'accès réseau** :
   ```bash
   # Sur la machine qui héberge l'API
   curl http://0.0.0.0:8080/health
   
   # Depuis une autre machine (remplacez IP_DE_LA_MACHINE)
   curl http://IP_DE_LA_MACHINE:8080/health
   ```

3. **Vérifiez le firewall** :
   ```bash
   # macOS : autoriser le port 8080
   sudo ufw allow 8080
   
   # Ou désactiver temporairement le firewall pour tester
   ```

### Problèmes de base de données

Si PostgreSQL ne démarre pas :
```bash
# Supprimer les volumes Docker et redémarrer
docker-compose down -v
./dev-start.sh
```

## 📊 Services

- **Health** : Vérification de l'état de l'API
- **Market** : Données de marché et prix
- **Users** : Gestion des utilisateurs et portfolios
- **WebSocket** : Mises à jour en temps réel

## 🧪 Tests

```bash
# Tests unitaires
cargo test

# Linting
cargo clippy
```

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