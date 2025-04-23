// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

/**
 * @title ILendingPoolFactory
 * @notice Interface pour la factory de pools
 */
interface ILendingPoolFactory {
    function createPool(
        address asset,
        string memory name,
        string memory symbol,
        uint256 collateralRatio
    ) external returns (address);

    function getPool(address asset) external view returns (address);
    function getAllPools() external view returns (address[] memory);
    function getPoolCount() external view returns (uint256);
}
