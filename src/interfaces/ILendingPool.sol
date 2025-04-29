// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

/**
 * @title ILendingPool
 * @notice Interface pour la pool de prêt
 */
interface ILendingPool {
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 amount) external;
    function supplyCollateral(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay(uint256 amount) external payable;

    function updateInterestRate() external;
    function currentInterestRate() external view returns (uint256);
    function totalDeposits() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function collateralSupplied(address user) external view returns (uint256);
    function userBorrows(address user) external view returns (uint256);
    function asset() external view returns (address);
    function cToken() external view returns (address);
    function collateralRatio() external view returns (uint256);
}