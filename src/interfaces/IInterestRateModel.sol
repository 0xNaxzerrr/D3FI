// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

/**
 * @title IInterestRateModel
 * @notice Interface pour le modèle de calcul de taux d'intérêt
 */
interface IInterestRateModel {
    function calculateInterestRate(uint256 utilizationRatio) external view returns (uint256);
}