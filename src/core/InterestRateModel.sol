// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title InterestRateModel
 * @notice Modèle de calcul des taux d'intérêt pour les pools de prêt
 */
contract InterestRateModel is Ownable {
    // Paramètres configurables (en points de base: 1% = 100 points)
    uint256 public baseRate;            // Taux de base
    uint256 public slopeRate1;          // Première pente
    uint256 public slopeRate2;          // Seconde pente
    uint256 public optimalUtilizationRate; // Taux d'utilisation optimal
    uint256 public minRate;             // Taux minimum
    uint256 public maxRate;             // Taux maximum

    event ParametersUpdated(
        uint256 baseRate,
        uint256 slopeRate1,
        uint256 slopeRate2,
        uint256 optimalUtilizationRate,
        uint256 minRate,
        uint256 maxRate
    );

    constructor(
        uint256 _baseRate,
        uint256 _slopeRate1,
        uint256 _slopeRate2,
        uint256 _optimalUtilizationRate,
        uint256 _minRate,
        uint256 _maxRate
    ) {
        baseRate = _baseRate;
        slopeRate1 = _slopeRate1;
        slopeRate2 = _slopeRate2;
        optimalUtilizationRate = _optimalUtilizationRate;
        minRate = _minRate;
        maxRate = _maxRate;
    }

    /**
     * @notice Calcule le taux d'intérêt en fonction du ratio d'utilisation
     * @param utilizationRatio Ratio d'utilisation (en points de base, ex: 8000 = 80%)
     */
    function calculateInterestRate(uint256 utilizationRatio)
    external
    view
    returns (uint256)
    {
        uint256 interestRate;

        if (utilizationRatio < optimalUtilizationRate) {
            // Première zone: utilisation sous le niveau optimal
            interestRate = baseRate + (utilizationRatio * slopeRate1 / 10000);
        } else {
            // Seconde zone: utilisation élevée (au-dessus du niveau optimal)
            uint256 excessUtilization = utilizationRatio - optimalUtilizationRate;
            interestRate = baseRate +
                (optimalUtilizationRate * slopeRate1 / 10000) +
                (excessUtilization * slopeRate2 / 10000);
        }

        // Application des limites min/max
        if (interestRate < minRate) {
            return minRate;
        }
        if (interestRate > maxRate) {
            return maxRate;
        }

        return interestRate;
    }

    /**
     * @notice Permet à l'admin de mettre à jour tous les paramètres
     */
    function updateParameters(
        uint256 _baseRate,
        uint256 _slopeRate1,
        uint256 _slopeRate2,
        uint256 _optimalUtilizationRate,
        uint256 _minRate,
        uint256 _maxRate
    ) external onlyOwner {
        require(_minRate < _maxRate, "Min doit être < max");
        require(_optimalUtilizationRate <= 10000, "Taux doit être <= 100%");

        baseRate = _baseRate;
        slopeRate1 = _slopeRate1;
        slopeRate2 = _slopeRate2;
        optimalUtilizationRate = _optimalUtilizationRate;
        minRate = _minRate;
        maxRate = _maxRate;

        emit ParametersUpdated(
            _baseRate,
            _slopeRate1,
            _slopeRate2,
            _optimalUtilizationRate,
            _minRate,
            _maxRate
        );
    }
}