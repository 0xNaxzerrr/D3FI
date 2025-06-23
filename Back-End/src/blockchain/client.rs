use crate::core::price_ws_service::PriceUpdate;
use anyhow::{Context, Result};
use ethers::{
    prelude::*,
    providers::{Http, Provider},
    signers::LocalWallet,
    types::{Address, U256},
};
use std::str::FromStr;
use std::sync::Arc;
use tracing::info;

// Constantes pour la connexion Ethereum
const RPC_URL: &str = "http://localhost:8545"; // À ajuster selon votre configuration
const PRIVATE_KEY: &str = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Clé de test uniquement

// Structure du contrat de liquidation
#[derive(Debug)]
pub struct LiquidationContract {
    contract: ethers::contract::Contract<Provider<Http>>,
    wallet: LocalWallet,
    provider: Provider<Http>,
}

impl LiquidationContract {
    // Créer une nouvelle instance du contrat
    pub async fn new(contract_address: &str) -> Result<Self> {
        // Connexion au noeud Ethereum
        let provider = Provider::<Http>::try_from(RPC_URL)?;
        
        // Configuration du wallet pour signer les transactions
        let wallet = LocalWallet::from_str(PRIVATE_KEY)?
            .with_chain_id(Chain::Sepolia); // À ajuster selon votre réseau (Mainnet, Goerli, etc.)
        
        // Définition de l'ABI du contrat (à remplacer par le vrai ABI quand il sera disponible)
        let abi = r#"[
            {
                "inputs": [
                    {"name": "userAddress", "type": "address"},
                    {"name": "btcPrice", "type": "uint256"},
                    {"name": "ethPrice", "type": "uint256"}
                ],
                "name": "liquidateUser",
                "outputs": [{"name": "", "type": "bool"}],
                "stateMutability": "nonpayable",
                "type": "function"
            }
        ]"#;
        
        // Créer une instance du contrat
        let contract_addr = Address::from_str(contract_address)
            .with_context(|| format!("Invalid contract address: {}", contract_address))?;
        
        let abi_parsed: ethers::abi::Abi = serde_json::from_str(abi)?;
        
        let contract = ethers::contract::Contract::new(
            contract_addr,
            abi_parsed,
            Arc::new(provider.clone()),
        );
        
        Ok(Self {
            contract,
            wallet,
            provider,
        })
    }
    
    // Liquider un utilisateur
    pub async fn liquidate_user(
        &self, 
        user_address: &str, 
        btc_price: &PriceUpdate, 
        eth_price: &PriceUpdate
    ) -> Result<String> {
        info!("Liquidation de l'utilisateur {} avec BTC=${} et ETH=${}", 
             user_address, btc_price.price, eth_price.price);
        
        let user_addr = Address::from_str(user_address)
            .with_context(|| format!("Invalid user address: {}", user_address))?;
        
        // Convertir les prix en format utilisable par le contrat (entiers)
        // Exemple : multiplier par 10^8 pour avoir 8 décimales de précision
        let btc_price_scaled = U256::from((btc_price.price * 100_000_000.0) as u64);
        let eth_price_scaled = U256::from((eth_price.price * 100_000_000.0) as u64);
        
        // Créer un client connecté avec le wallet
        let client = Arc::new(SignerMiddleware::new(
            self.provider.clone(),
            self.wallet.clone(),
        ));
        
        // Connecter le contrat au client
        let contract = self.contract.connect(client);
        
        // Appeler la fonction de liquidation
        let method_call = contract.method::<_, bool>(
            "liquidateUser", 
            (user_addr, btc_price_scaled, eth_price_scaled)
        )?;
        
        let pending_tx = method_call.legacy();
        let tx = pending_tx.send().await?;
        
        info!("Transaction de liquidation envoyée: {:?}", tx.tx_hash());
        
        // Attendre que la transaction soit confirmée
        let receipt = tx.await?
            .context("La transaction de liquidation a échoué")?;
        
        info!("Liquidation confirmée, block: {}", receipt.block_number.unwrap_or_default());
        
        Ok(format!("{:?}", receipt.transaction_hash))
    }
}
