// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Script.sol";
import "../src/core/LendingPoolFactory.sol";
import "../src/utils/PriceOracle.sol";
import "../src/core/InterestRateModel.sol";

contract DeploySepoliaContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        require(block.chainid == 11155111, "Ce script est concu pour Sepolia uniquement");

        vm.startBroadcast(deployerPrivateKey);

        // Déploiement des contrats
        PriceOracle oracle = new PriceOracle();
        InterestRateModel interestRateModel = new InterestRateModel(
            1e16,  // baseRate: 1%
            2e16,  // slopeRate1: 2%
            4e16,  // slopeRate2: 4%
            8e17,  // optimalUtilizationRate: 80%
            5e15,  // minRate: 0.5%
            2e17   // maxRate: 20%
        );
        
        // Déploiement de la factory
        LendingPoolFactory factory = new LendingPoolFactory(address(oracle));

        // Autoriser la factory à appeler setPriceFeed sur l'oracle
        oracle.authorizeCaller(address(factory));

        vm.stopBroadcast();

        console.log("Addresses des contrats deployes:");
        console.log("Oracle:", address(oracle));
        console.log("InterestRateModel:", address(interestRateModel));
        console.log("Factory:", address(factory));
        console.log("\nCommande pour creer un pool ETH:");
        console.log("cast send $FACTORY \"createPool(address,string,string,uint256,address)\" 0x0 \"Ethereum\" \"ETH\" 15000 0x694AA1769357215DE4FAC081bf1f309aDC325306 --rpc-url $RPC_URL_SEPOLIA --private-key $PRIVATE_KEY");
    }
}