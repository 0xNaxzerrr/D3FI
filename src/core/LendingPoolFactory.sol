// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LendingPool.sol";
import "../tokens/CToken.sol";
import "./InterestRateModel.sol";

/**
 * @title AToken
 * @notice Interface minimale du token de dépôt
 */
interface IAToken {
    function setLendingPool(address pool) external;
}

/**
 * @title LendingPoolFactory
 * @notice Permet aux admins de créer des pools de prêt pour différents actifs
 */
contract LendingPoolFactory is Ownable {
    // Mapping des pools par actif
    mapping(address => address) public assetToPools;
    address[] public allPools;

    // Événements
    event PoolCreated(
        address indexed asset,
        address indexed pool,
        address aToken,
        address cToken,
        string name,
        string symbol
    );

    /**
     * @notice Crée une nouvelle pool de prêt pour un actif
     * @param asset Adresse du token (address(0) pour ETH)
     * @param name Nom descriptif de l'actif (ex: "Ethereum")
     * @param symbol Symbole de l'actif (ex: "ETH")
     * @param collateralRatio Ratio de collatéral (ex: 15000 = 150%)
     */
    function createPool(
        address asset,
        string memory name,
        string memory symbol,
        uint256 collateralRatio
    ) external onlyOwner returns (address) {
        require(assetToPools[asset] == address(0), "Pool déjà existante");
        require(collateralRatio >= 10000, "Ratio doit être >= 100%");

        // Créer les tokens pour la pool
        string memory aTokenName = string(abi.encodePacked("D3FI ", name, " Deposit"));
        string memory aTokenSymbol = string(abi.encodePacked("a", symbol));

        string memory cTokenName = string(abi.encodePacked("D3FI ", name, " Collateral"));
        string memory cTokenSymbol = string(abi.encodePacked("c", symbol));

        // Déployer les contrats
        CToken _aToken = new CToken(aTokenName, aTokenSymbol, asset);
        CToken _cToken = new CToken(cTokenName, cTokenSymbol, asset);

        InterestRateModel _interestRateModel = new InterestRateModel(
            500,    // baseRate (5%)
            1000,   // slopeRate1 (10%)
            5000,   // slopeRate2 (50%)
            8000,   // optimalUtilizationRate (80%)
            200,    // minRate (2%)
            15000   // maxRate (150%)
        );

        // Créer la pool
        LendingPool pool = new LendingPool(
            asset,
            address(_aToken),
            address(_cToken),
            address(_interestRateModel),
            collateralRatio
        );

        // Configurer les permissions
        _aToken.setLendingPool(address(pool));
        _cToken.setLendingPool(address(pool));
        _interestRateModel.transferOwnership(address(pool));

        // Enregistrer la pool
        assetToPools[asset] = address(pool);
        allPools.push(address(pool));

        emit PoolCreated(
            asset,
            address(pool),
            address(_aToken),
            address(_cToken),
            name,
            symbol
        );

        return address(pool);
    }

    /**
     * @notice Récupère l'adresse de la pool pour un actif
     * @param asset Adresse de l'actif
     */
    function getPool(address asset) external view returns (address) {
        return assetToPools[asset];
    }

    /**
     * @notice Récupère toutes les pools créées
     */
    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }

    /**
     * @notice Récupère le nombre de pools
     */
    function getPoolCount() external view returns (uint256) {
        return allPools.length;
    }
}