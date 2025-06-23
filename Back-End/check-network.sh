#!/bin/bash

# Script de diagnostic réseau pour D3FI API
set -e

echo "🔍 Diagnostic réseau D3FI API..."
echo ""

# Vérifier le fichier .env
echo "📋 Vérification de la configuration..."
if [ -f .env ]; then
    echo "✅ Fichier .env trouvé"
    
    # Vérifier API_HOST
    if grep -q "API_HOST=0.0.0.0" .env; then
        echo "✅ API_HOST configuré correctement (0.0.0.0)"
    elif grep -q "API_HOST=127.0.0.1" .env; then
        echo "❌ API_HOST configuré sur 127.0.0.1 (accès local uniquement)"
        echo "   🔧 Changez en API_HOST=0.0.0.0 pour l'accès réseau"
    else
        echo "⚠️  API_HOST non trouvé dans .env"
    fi
    
    # Vérifier API_PORT
    port=$(grep "API_PORT=" .env | cut -d'=' -f2)
    if [ ! -z "$port" ]; then
        echo "✅ API_PORT configuré sur $port"
    else
        echo "⚠️  API_PORT non trouvé dans .env"
        port=8080
    fi
else
    echo "❌ Fichier .env non trouvé"
    echo "   🔧 Lancez: cp env.example .env"
    port=8080
fi

echo ""

# Obtenir l'IP de la machine
echo "🌐 Informations réseau:"
echo "   Localhost: 127.0.0.1:$port"

# IP locale (première IP non-localhost trouvée)
local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
if [ ! -z "$local_ip" ]; then
    echo "   IP locale: $local_ip:$port"
    echo ""
    echo "📱 Pour accéder depuis d'autres machines:"
    echo "   http://$local_ip:$port/health"
    echo "   http://$local_ip:$port/swagger-ui"
else
    echo "   ⚠️  IP locale non détectée"
fi

echo ""

# Vérifier si l'API est en cours d'exécution
echo "🔍 Vérification de l'API..."
if curl -s http://127.0.0.1:$port/health > /dev/null 2>&1; then
    echo "✅ API accessible localement"
    
    # Test d'accès depuis l'IP locale si disponible
    if [ ! -z "$local_ip" ]; then
        if curl -s http://$local_ip:$port/health > /dev/null 2>&1; then
            echo "✅ API accessible depuis le réseau"
        else
            echo "❌ API non accessible depuis le réseau"
            echo "   🔧 Vérifiez le firewall ou API_HOST dans .env"
        fi
    fi
else
    echo "❌ API non accessible"
    echo "   🔧 Lancez: cargo run"
fi

echo ""

# Vérifier les ports occupés
echo "🔍 Ports en écoute:"
netstat -an | grep ":$port" | head -3

echo ""
echo "🎯 Commandes utiles:"
echo "   Test local:  curl http://127.0.0.1:$port/health"
if [ ! -z "$local_ip" ]; then
    echo "   Test réseau: curl http://$local_ip:$port/health"
fi
echo "   Logs API:    cargo run"
echo "   Firewall:    sudo ufw allow $port" 