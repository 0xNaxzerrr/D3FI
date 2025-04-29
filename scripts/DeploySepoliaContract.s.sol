// scripts/DeploySepoliaContract.s.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Script.sol";
import "../src/core/LendingPoolFactory.sol";
import "../src/utils/PriceOracle.sol";

contract DeploySepoliaContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploiement sur Sepolia avec l'adresse:", deployer);

        // Vérification que nous sommes sur Sepolia (chainId 11155111)
        require(block.chainid == 11155111, "Ce script est concu pour Sepolia uniquement");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Déployer l'oracle
        PriceOracle oracle = new PriceOracle();
        console.log("PriceOracle deploye a:", address(oracle));

        // 2. Déployer la factory
        LendingPoolFactory factory = new LendingPoolFactory();
        console.log("LendingPoolFactory deploye a:", address(factory));

        // 3. Configurer l'oracle dans la factory
        factory.setPriceOracle(address(oracle));

        // 4. Configurer les price feeds pour ETH
        address ethUsdFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ETH/USD sur Sepolia
        oracle.setPriceFeed(address(0), ethUsdFeed); // address(0) représente ETH

        // 5. Créer une pool pour ETH
        address ethPool = factory.createPool(
            address(0),      // ETH
            "Ethereum",      // Nom
            "ETH",           // Symbole
            15000            // Ratio de collatéral 150%
        );
        console.log("Pool ETH creee a:", ethPool);

        vm.stopBroadcast();
    }
}