// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../interfaces/ILendingPoolFactory.sol";
import "../interfaces/IPriceOracle.sol";
import "./LendingPool.sol";
import "../tokens/CToken.sol";
import "../core/InterestRateModel.sol";
import "../utils/PriceOracle.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title LendingPoolFactory
 * @notice Permet aux admins de créer des pools de prêt pour différents actifs
 */
contract LendingPoolFactory is ILendingPoolFactory, Ownable {
    // Mapping des actifs vers leurs pools
    mapping(address => address) public override assetToPools;
    
    // Tableau de toutes les pools créées
    address[] private _pools;
    
    // Oracle de prix
    address public override priceOracle;
    
    // Gestion des frais du protocole
    uint256 public override protocolFeeRate = 50; // 0.5% par défaut
    uint256 public override totalProtocolFees;

    constructor(address _priceOracle) {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = _priceOracle;
        protocolFeeRate = 50; // 0.5% par défaut
    }

    /**
     * @notice Met à jour le taux de frais du protocole
     * @param _newRate Nouveau taux de frais (en base points)
     */
    function updateProtocolFeeRate(uint256 _newRate) external override onlyOwner {
        require(_newRate <= 1000, "Fee rate too high"); // Max 10%
        protocolFeeRate = _newRate;
        emit ProtocolFeeRateUpdated(_newRate);
    }

    /**
     * @notice Récupère tous les frais accumulés du protocole
     */
    function collectProtocolFees() external override onlyOwner {
        require(totalProtocolFees > 0, "No fees to collect");
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;

        (bool success, ) = owner().call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ProtocolFeesCollected(amount);
    }

    /**
     * @notice Récupère le total des frais accumulés
     */
    function getTotalProtocolFees() external view override returns (uint256) {
        return totalProtocolFees;
    }

    /**
     * @notice Récupère le taux de frais actuel
     */
    function getProtocolFeeRate() external view override returns (uint256) {
        return protocolFeeRate;
    }

    /**
     * @notice Ajoute des frais au total
     * @param amount Montant des frais à ajouter
     */
    function addProtocolFees(uint256 amount) external {
        // Permettre à la factory elle-même d'ajouter des frais
        if (msg.sender == address(this)) {
            totalProtocolFees += amount;
            return;
        }

        // Permettre aux pools enregistrées d'ajouter des frais
        require(_isPool(msg.sender), "Not authorized");
        totalProtocolFees += amount;
    }

    // Fonction interne pour vérifier si une adresse est une pool
    function _isPool(address poolAddress) internal view returns (bool) {
        for (uint256 i = 0; i < _pools.length; i++) {
            if (_pools[i] == poolAddress) {
                return true;
            }
        }
        return false;
    }

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
     * @notice Crée une nouvelle pool de prêt pour un actif avec son price feed
     * @param _asset Adresse du token (address(0) pour ETH)
     * @param _name Nom descriptif de l'actif (ex: "Ethereum")
     * @param _symbol Symbole de l'actif (ex: "ETH")
     * @param _collateralRatio Ratio de collatéral (ex: 15000 = 150%)
     * @param _priceFeed Adresse du price feed Chainlink pour cet actif
     */
    function createPool(
        address _asset,
        string memory _name,
        string memory _symbol,
        uint256 _collateralRatio,
        address _priceFeed
    ) external onlyOwner returns (address) {
        require(_asset != address(0) || _asset == address(0), "Invalid asset address");
        require(_collateralRatio >= 10000, "Collateral ratio must be >= 100%");
        require(_priceFeed != address(0), "Price feed address cannot be zero");
        require(assetToPools[_asset] == address(0), "Pool already exists for this asset");

        // Vérifier que le price feed est bien enregistré dans l'oracle
        require(PriceOracle(priceOracle).priceFeedSource(_asset) != address(0), "Price feed not registered");

        // Créer le CToken
        CToken newCToken = new CToken(_name, _symbol, _asset);
        
        // Créer le modèle de taux d'intérêt avec les paramètres par défaut
        InterestRateModel newInterestRateModel = new InterestRateModel(
            500,    // baseRate (5%)
            1000,   // slopeRate1 (10%)
            5000,   // slopeRate2 (50%)
            8000,   // optimalUtilizationRate (80%)
            200,    // minRate (2%)
            15000   // maxRate (150%)
        );
        
        // Créer la pool
        LendingPool newPool = new LendingPool(
            _asset,
            address(newCToken),
            address(newInterestRateModel),
            address(priceOracle),
            _collateralRatio
        );

        // Lier le CToken à la LendingPool
        newCToken.setLendingPool(address(newPool));
        
        // Enregistrer la pool
        assetToPools[_asset] = address(newPool);
        _pools.push(address(newPool));
        
        // Enregistrer le price feed
        PriceOracle(priceOracle).setPriceFeed(_asset, _priceFeed);

        emit PoolCreated(_asset, address(newPool), address(newCToken), _name, _symbol);

        return address(newPool);
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
        return _pools;
    }

    /**
     * @notice Récupère le nombre de pools
     */
    function getPoolCount() external view returns (uint256) {
        return _pools.length;
    }

    function collectAllProtocolFees() external onlyOwner {
        uint256 totalFees = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            LendingPool pool = LendingPool(payable(_pools[i]));
            // Vérifier que la pool appartient à la factory
            require(pool.owner() == address(this), "Pool not owned by factory");
            uint256 fees = pool.protocolFees();
            if (fees > 0) {
                pool.collectProtocolFees();
                totalFees += fees;
            }
        }
        require(totalFees > 0, "No fees to collect");
        totalProtocolFees += totalFees;
        emit ProtocolFeesCollected(totalFees);
    }

    function getUserPools(address user) external view returns (LendingPool[] memory) {
        LendingPool[] memory userPools = new LendingPool[](_pools.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < _pools.length; i++) {
            LendingPool pool = LendingPool(payable(_pools[i]));
            if (pool.userBorrows(user) > 0 || pool.collateralSupplied(user) > 0) {
                userPools[count] = pool;
                count++;
            }
        }

        // Redimensionner le tableau pour n'inclure que les pools utilisées
        assembly {
            mstore(userPools, count)
        }

        return userPools;
    }
}
