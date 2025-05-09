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
        console.log("Oracle configure dans la Factory");

        vm.stopBroadcast();

        console.log("");
        console.log("Deploiement termine. Addresses des contrats:");
        console.log("Oracle:", address(oracle));
        console.log("Factory:", address(factory));
        console.log("");
        console.log("Pour creer des pools, utilise ces commandes:");
        console.log("ETH Pool: cast send $FACTORY \"createPool(address,string,string,uint256,address)\" 0x0 \"Ethereum\" \"ETH\" 15000 0x694AA1769357215DE4FAC081bf1f309aDC325306 --rpc-url $RPC_URL_SEPOLIA --private-key $PRIVATE_KEY");
    }
}