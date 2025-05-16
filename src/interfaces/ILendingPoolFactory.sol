// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../core/LendingPool.sol";

/**
 * @title ILendingPoolFactory
 * @notice Interface pour la factory de pools
 */
interface ILendingPoolFactory {
    // Variables d'état
    function assetToPools(address) external view returns (address);
    function priceOracle() external view returns (address);
    function protocolFeeRate() external view returns (uint256);

    // Événements
    event PoolCreated(address indexed asset, address indexed pool, address cToken, string name, string symbol);
    event ProtocolFeeRateUpdated(uint256 newRate);
    event ProtocolFeesCollected(uint256 amount);

    // Fonctions de gestion des frais
    function updateProtocolFeeRate(uint256 _newRate) external;
    function collectAllProtocolFees() external;
    function getProtocolFeeRate() external view returns (uint256);

    // Fonctions existantes
    function createPool(
        address asset,
        string memory name,
        string memory symbol,
        uint256 collateralRatio,
        address priceFeed
    ) external returns (address);
    
    function getPool(address asset) external view returns (address);
    function getAllPools() external view returns (address[] memory);
    function getPoolCount() external view returns (uint256);
    function getUserPools(address user) external view returns (LendingPool[] memory);
}
