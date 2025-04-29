// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "./LendingPool.sol";
import "../tokens/CToken.sol";
import "./InterestRateModel.sol";
import "../utils/PriceOracle.sol";

/**
 * @title LendingPoolFactory
 * @notice Permet aux admins de créer des pools de prêt pour différents actifs
 */
contract LendingPoolFactory is Ownable {

    address public priceOracle;

    // Mapping des pools par actif
    mapping(address => address) public assetToPools;
    address[] public allPools;

    event PoolCreated(address indexed asset, address indexed pool, address cToken, string name, string symbol);
    event PriceOracleSet(address indexed oracle);


    /**
     * @notice Définit l'oracle de prix
     * @param _priceOracle Adresse du contrat oracle
     */
    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = _priceOracle;
        emit PriceOracleSet(_priceOracle);
    }

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
        require(assetToPools[asset] == address(0), "Pool already exists for this asset");
        require(collateralRatio >= 10000, "Ratio must be >= 100%");

        // Créer un seul token pour la pool
        string memory cTokenName = string(abi.encodePacked("D3FI ", name, " Token"));
        string memory cTokenSymbol = string(abi.encodePacked("c", symbol));

        // Déployer les contrats
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
            address(_cToken),
            address(_interestRateModel),
            priceOracle,
            collateralRatio
        );

        // Configurer les permissions
        _cToken.setLendingPool(address(pool));
        _interestRateModel.transferOwnership(address(pool));

        // Enregistrer la pool
        assetToPools[asset] = address(pool);
        allPools.push(address(pool));

        emit PoolCreated(
            asset,
            address(pool),
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