// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../interfaces/ILendingPoolFactory.sol";
import "../interfaces/IPriceOracle.sol";
import "./LendingPool.sol";
import "../tokens/CToken.sol";
import "../core/InterestRateModel.sol";
import "../utils/PriceOracle.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title LendingPoolFactory
 * @notice Permet aux admins de créer des pools de prêt pour différents actifs
 */
contract LendingPoolFactory is ILendingPoolFactory, Ownable {
    using SafeERC20 for IERC20;

    // Mapping des actifs vers leurs pools
    mapping(address => address) public override assetToPools;
    
    // Tableau de toutes les pools créées
    address[] private _pools;
    
    // Oracle de prix
    address public override priceOracle;
    
    // Taux de frais du protocole
    uint256 public override protocolFeeRate = 50; // 0.5% par défaut

    constructor(address _priceOracle) {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = _priceOracle;
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
     * @notice Récupère le taux de frais actuel
     */
    function getProtocolFeeRate() external view override returns (uint256) {
        return protocolFeeRate;
    }

    /**
     * @notice Collecte les frais de toutes les pools
     */
    function collectAllProtocolFees() external onlyOwner {
        uint256 totalFees = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            LendingPool pool = LendingPool(payable(_pools[i]));
            uint256 fees = pool.protocolFees();
            if (fees > 0) {
                pool.collectProtocolFees();
                totalFees += fees;
            }
        }
        require(totalFees > 0, "No fees to collect");
        emit ProtocolFeesCollected(totalFees);
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
        require(_collateralRatio >= 10000, "Collateral ratio must be >= 100%");
        require(_priceFeed != address(0), "Price feed address cannot be zero");
        require(assetToPools[_asset] == address(0), "Pool already exists for this asset");

        // Vérifier que le price feed est bien enregistré dans l'oracle
        require(PriceOracle(priceOracle).priceFeedSource(_asset) != address(0), "Price feed not registered");

        // Créer le CToken
        CToken newCToken = new CToken(_name, _symbol, _asset);
        
        // Enregistrer automatiquement le price feed pour le cToken
        PriceOracle(priceOracle).setPriceFeed(address(newCToken), _priceFeed);
        
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

    /**
     * @notice Transfère les frais collectés de la factory vers l'owner
     * @param token Adresse du token à transférer (address(0) pour ETH)
     */
    function withdrawFees(address token) external onlyOwner {
        if (token == address(0)) {
            uint256 ethBalance = address(this).balance;
            require(ethBalance > 0, "No ETH fees to withdraw");
            (bool success, ) = owner().call{value: ethBalance}("");
            require(success, "ETH transfer failed");
            emit FeesWithdrawn(token, ethBalance);
        } else {
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            require(tokenBalance > 0, "No token fees to withdraw");
            IERC20(token).safeTransfer(owner(), tokenBalance);
            emit FeesWithdrawn(token, tokenBalance);
        }
    }

    // Événement pour le suivi des retraits de frais
    event FeesWithdrawn(address indexed token, uint256 amount);

    // Permet à la factory de recevoir de l'ETH (pour collectProtocolFees sur pool ETH)
    receive() external payable {}
}

