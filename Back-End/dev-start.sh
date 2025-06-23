#!/bin/bash

# Script de démarrage simplifié pour développeurs
set -e

echo "🚀 Démarrage de l'environnement de développement D3FI API..."

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier que Rust est installé
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust n'est pas installé."
    echo "📋 Installez Rust avec : curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo "📋 Création du fichier .env..."
    cp env.example .env
    echo "✅ Fichier .env créé."
fi

# Démarrer PostgreSQL et Redis avec Docker
echo "🐳 Démarrage de PostgreSQL et Redis..."
docker-compose up -d postgres redis

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente que PostgreSQL soit prêt..."
sleep 10

# Vérifier si SQLx CLI est installé
if ! command -v sqlx &> /dev/null; then
    echo "📦 Installation de SQLx CLI..."
    cargo install sqlx-cli
fi

# Exécuter les migrations
echo "🗃️ Exécution des migrations de base de données..."
sqlx migrate run

echo ""
echo "✅ Environnement de développement prêt!"
echo ""
echo "📊 Services disponibles:"
echo "   - PostgreSQL:   localhost:5432"
echo "   - Redis:        localhost:6379"
echo ""
echo "🚀 Pour démarrer l'API:"
echo "   cargo run"
echo ""
echo "📝 L'API sera disponible sur http://localhost:8080"
echo "📚 Documentation Swagger : http://localhost:8080/docs"
echo ""
echo "🛑 Pour arrêter les services Docker:"
echo "   docker-compose down" 