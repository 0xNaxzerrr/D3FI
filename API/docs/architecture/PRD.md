D3FI - API

### Aperçu du Projet
Ce projet vise à développer l'API backend en Rust pour une plateforme décentralisée de prêt et d'emprunt (lending & borrowing) sur la blockchain Ethereum. L'API servira d'interface entre les smart contracts Solidity et l'application frontend.

## Objectifs

1. Fournir une API performante et sécurisée pour accéder aux données des smart contracts
2. Implémenter un système de surveillance en temps réel des health factors
3. Développer un mécanisme d'alerte et de notification pour les positions à risque
4. Faciliter la gestion des liquidations automatiques
5. Offrir une expérience utilisateur optimale pour les opérations de prêt et d'emprunt

## Fonctionnalités Principales

1. Surveillance des Health Factors
Objectif: Surveiller en temps réel la santé des positions collatéralisées pour prévenir les liquidations imprévues.
Fonctionnalités:

Calcul périodique du health factor pour toutes les positions actives
Classification des positions selon leur niveau de risque
Historisation des health factors pour analyse de tendance

Niveaux de risque:

Niveau sécurisé: Health factor > 1.5 → Pas d'alerte
Niveau d'avertissement: 1.2 < Health factor < 1.5 → Notification d'avertissement
Niveau critique: 1.05 < Health factor < 1.2 → Notification urgente
Niveau pré-liquidation: 1.0 < Health factor < 1.05 → Alerte en temps réel
Liquidation: Health factor ≤ 1.0 → Notification de liquidation

2. Système de Notification
Objectif: Informer proactivement les utilisateurs des changements de statut de leurs positions.
Fonctionnalités:

Notifications en temps réel via WebSockets
Notifications configurables selon les préférences utilisateur
Support multi-niveaux d'alertes selon la gravité

3. Gestion des Liquidations
Objectif: Faciliter le processus de liquidation des positions sous-collatéralisées.
Fonctionnalités:

Détection automatique des positions liquidables
Déclenchement des transactions de liquidation
Notification des liquidations effectuées

4. Interface avec la Blockchain
Objectif: Optimiser les interactions avec la blockchain Ethereum.
Fonctionnalités:

Cache intelligent des données blockchain fréquemment consultées
Écoute des événements pertinents des smart contracts
Soumission de transactions pour les liquidations

## Architecture Technique

# Stack Technologique

- Langage: Rust
- Framework Web: Axum ou Actix-web
- Interaction Blockchain: ethers-rs
- Base de données: PostgreSQL (données persistantes) + Redis (cache)
- Communication asynchrone: Tokio
- WebSockets: tokio-tungstenite
- Conteneurisation: Docker
- Monitoring: Prometheus + Grafana

# Structure de l'Application
L'application est structurée en une API Rust unifiée qui expose deux types d'interfaces:

API REST pour les requêtes ponctuelles et les opérations CRUD
WebSockets pour les communications en temps réel

# Les services internes (Core Services) encapsulent la logique métier:

- Health Monitor Service: Surveillance des health factors
- Notification Service: Gestion des alertes
- Liquidation Trigger Service: Déclenchement des liquidations
- Blockchain Cache Service: Interface optimisée avec la blockchain

## Spécifications des API

Endpoints REST

```bash 
GET  /api/v1/health                     # Statut de l'API
POST /api/v1/auth                       # Authentification (si nécessaire)

# Données du marché
GET  /api/v1/market/stats               # Statistiques globales du marché
GET  /api/v1/market/assets              # Liste des actifs supportés
GET  /api/v1/market/rates               # Taux d'intérêt actuels

# Données utilisateur
GET  /api/v1/users/:address/portfolio   # Positions d'un utilisateur 
GET  /api/v1/users/:address/health      # Santé du collatéral d'un utilisateur
GET  /api/v1/users/:address/history     # Historique des transactions

# Configuration des notifications
POST /api/v1/users/:address/notifications/settings    # Configurer les préférences
GET  /api/v1/users/:address/notifications/history     # Historique des notifications

# Données du health factor
GET  /api/v1/users/:address/health/current            # Health factor actuel
GET  /api/v1/users/:address/health/history            # Historique du health factor
```

Endpoints WebSocket

```bash
/ws/health/:address       # Mises à jour du health factor en temps réel
/ws/notifications/:address # Notifications utilisateur
/ws/market                # Mises à jour du marché (taux, utilisation des pools)
```

## Considérations et Contraintes

# Performance

- L'API doit supporter un nombre élevé de connexions simultanées
- Les calculs de health factor doivent être optimisés pour réduire la latence 

# Sécurité

- Validation rigoureuse des entrées utilisateur
- Protection contre les attaques DDoS
- Vérification des signatures pour les opérations sensibles

# Scalabilité

- Architecture permettant la mise à l'échelle horizontale
- Services indépendants pouvant évoluer séparément

# Fiabilité

- Mécanismes de reprise après panne
- Journalisation complète des événements
- Stratégie de sauvegarde des données critiques

# Métriques de Succès

- Réduction du taux de liquidations involontaires
- Taux élevé d'actions préventives suite aux alertes
- Latence minimale pour les calculs de health factor
- Haute disponibilité du système (>99.9%)

# Plan de Mise en Œuvre

Phase 1: Développement de l'infrastructure de base et connexion blockchain
Phase 2: Implémentation du monitoring des health factors
Phase 3: Développement du système de notification
Phase 4: Mise en place du mécanisme de liquidation
Phase 5: Tests d'intégration et de charge
Phase 6: Déploiement et surveillance