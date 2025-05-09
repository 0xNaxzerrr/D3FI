// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IInterestRateModel.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/ILendingPoolFactory.sol";

/**
 * @title LendingPool
 * @notice Gère les opérations de prêt et d'emprunt pour un actif spécifique
 */
contract LendingPool is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Adresses des contrats liés
    address public asset;              // Token sous-jacent (address(0) pour ETH)
    address public cToken;             // Token unique pour dépôt et collatéral
    address public interestRateModel;  // Modèle de taux d'intérêt
    address public factory;            // Adresse de la Factory
    address public priceOracle;

    // Paramètres de la pool
    uint256 public collateralRatio;    // Ratio de collatéral (ex: 15000 = 150%)
    uint256 public currentInterestRate; // Taux d'intérêt actuel
    uint256 public protocolFeeRate;    // Taux de frais du protocole (en base points, ex: 50 = 0.5%)
    uint256 public protocolFees;       // Frais accumulés du protocole

    // Variables d'état
    uint256 public totalDeposits;      // Total des actifs déposés
    uint256 public totalBorrows;       // Total des actifs empruntés
    uint256 public lastUpdateTimestamp; // Dernière mise à jour des intérêts

    // Mappings pour la gestion du collatéral
    mapping(address => uint256) public userBorrows;     // Montant emprunté par utilisateur
    mapping(address => uint256) public collateralSupplied; // Collatéral fourni par utilisateur

    // Événements
    event PoolInitialized(address indexed asset, address cToken, address interestRateModel);
    event InterestRateUpdated(uint256 utilizationRate, uint256 newRate);
    event CollateralRatioUpdated(uint256 newRatio);
    event ProtocolFeeRateUpdated(uint256 newRate);
    event ProtocolFeesCollected(uint256 amount);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event CollateralSupplied(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, uint256 protocolFee);
    event Repaid(address indexed user, uint256 amount, uint256 protocolFee);

    // Constantes pour le health factor
    uint256 public constant HEALTH_FACTOR_PRECISION = 1e18;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18; // 1.0

    /**
     * @notice Initialise une nouvelle pool de prêt
     * @param _asset Adresse du token sous-jacent (address(0) pour ETH)
     * @param _cToken Adresse du token unique
     * @param _interestRateModel Adresse du modèle de taux d'intérêt
     * @param _collateralRatio Ratio de collatéral initial (ex: 15000 = 150%)
     */
    constructor(
        address _asset,
        address _cToken,
        address _interestRateModel,
        address _priceOracle,
        uint256 _collateralRatio
    ) {
        require(_collateralRatio >= 10000, "Collateral ratio must be >= 100%");

        asset = _asset;
        cToken = _cToken;
        interestRateModel = _interestRateModel;
        collateralRatio = _collateralRatio;
        lastUpdateTimestamp = block.timestamp;
        priceOracle = _priceOracle;
        factory = msg.sender; // La Factory est le msg.sender lors de la création
        protocolFeeRate = 50; // 0.5% par défaut

        // Initialiser avec un taux par défaut
        currentInterestRate = 500; // 5%

        // Transférer la propriété au propriétaire de la Factory
        _transferOwnership(Ownable(msg.sender).owner());

        emit PoolInitialized(_asset, _cToken, _interestRateModel);
    }

    /**
     * @notice Met à jour le taux d'intérêt en fonction de l'utilisation actuelle
     */
    function updateInterestRate() public {
        if (totalDeposits == 0) {
            currentInterestRate = 500; // Taux par défaut de 5%
            return;
        }

        // Calcul du ratio d'utilisation
        uint256 utilizationRatio = (totalBorrows * 10000) / totalDeposits;

        // Obtention du nouveau taux depuis le modèle
        uint256 newRate = IInterestRateModel(interestRateModel).calculateInterestRate(utilizationRatio);
        currentInterestRate = newRate;

        emit InterestRateUpdated(utilizationRatio, newRate);
    }

    /**
     * @notice Permet à l'admin de mettre à jour le ratio de collatéral
     * @param _newRatio Nouveau ratio de collatéral
     */
    function updateCollateralRatio(uint256 _newRatio) external onlyOwner {
        require(_newRatio >= 10000, "Ratio must be at least 100%");
        collateralRatio = _newRatio;
        emit CollateralRatioUpdated(_newRatio);
    }

    /**
     * @notice Permet à l'admin de mettre à jour le modèle de taux d'intérêt
     * @param _newModel Nouvelle adresse du modèle
     */
    function updateInterestRateModel(address _newModel) external onlyOwner {
        require(_newModel != address(0), "Invalid address");
        interestRateModel = _newModel;
        updateInterestRate();
    }

    /**
     * @notice Met à jour le taux de frais du protocole
     * @param _newRate Nouveau taux de frais (en base points)
     */
    function updateProtocolFeeRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 1000, "Fee rate too high"); // Max 10%
        protocolFeeRate = _newRate;
        emit ProtocolFeeRateUpdated(_newRate);
    }

    /**
     * @notice Récupère les frais accumulés du protocole
     */
    function collectProtocolFees() external onlyOwner {
        require(protocolFees > 0, "No fees to collect");
        uint256 amount = protocolFees;
        protocolFees = 0;

        if (asset == address(0)) {
            (bool success, ) = owner().call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(asset).safeTransfer(owner(), amount);
        }

        emit ProtocolFeesCollected(amount);
    }

    /**
     * @notice Calcule les frais du protocole pour un montant
     * @param amount Montant sur lequel calculer les frais
     * @return Montant des frais
     */
    function _calculateProtocolFee(uint256 amount) internal view returns (uint256) {
        return (amount * protocolFeeRate) / 1e18;
    }

    function _addProtocolFees(uint256 amount) internal {
        if (amount > 0) {
            protocolFees += amount;
        }
    }

    /**
     * @notice Dépose des actifs dans la pool
     * @param amount Montant à déposer
     */
    function deposit(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be > 0");

        // Traitement différent pour ETH vs ERC20
        if (asset == address(0)) {
            require(msg.value == amount, "Incorrect ETH value");
        } else {
            require(msg.value == 0, "ETH not accepted for ERC20 deposit");
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }

        // Mettre à jour le total des dépôts
        totalDeposits += amount;

        // Frapper des CTokens pour l'utilisateur
        IToken(cToken).mint(msg.sender, amount);

        updateInterestRate();
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Retire des actifs de la pool
     * @param amount Montant à retirer
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(amount <= totalDeposits - totalBorrows, "Not enough liquidity");

        // Brûler les CTokens de l'utilisateur
        IToken(cToken).burn(msg.sender, amount);

        // Mettre à jour le total des dépôts
        totalDeposits -= amount;

        // Transférer les tokens à l'utilisateur
        if (asset == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }

        updateInterestRate();
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Fournit du collatéral pour emprunter
     * @param amount Montant du collatéral
     */
    function supplyCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");

        // Transférer des CTokens de l'utilisateur vers le contrat
        IERC20(cToken).safeTransferFrom(msg.sender, address(this), amount);

        // Mettre à jour le collatéral fourni
        collateralSupplied[msg.sender] += amount;

        emit CollateralSupplied(msg.sender, amount);
    }

    /**
     * @notice Retire du collatéral
     * @param amount Montant du collatéral à retirer
     */
    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(collateralSupplied[msg.sender] >= amount, "Insufficient collateral");

        // Vérifier que le retrait ne compromet pas les emprunts
        uint256 borrowValue = userBorrows[msg.sender];
        uint256 remainingCollateral = collateralSupplied[msg.sender] - amount;

        if (borrowValue > 0) {
            uint256 requiredCollateral = (borrowValue * collateralRatio) / 10000;
            require(remainingCollateral >= requiredCollateral, "Would breach collateral ratio");
        }

        // Mettre à jour le collatéral
        collateralSupplied[msg.sender] -= amount;

        // Transférer les CTokens vers l'utilisateur
        IERC20(cToken).safeTransfer(msg.sender, amount);

        emit CollateralWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Calcule le health factor d'un utilisateur
     * @param user Adresse de l'utilisateur
     * @return Le health factor (1e18 = 1.0)
     */
    function calculateHealthFactor(address user) public view returns (uint256) {
        uint256 borrowValue = userBorrows[user];
        if (borrowValue == 0) return type(uint256).max;

        uint256 collateralValue = collateralSupplied[user];
        if (collateralValue == 0) return 0;

        // Calculer la valeur en USD du collatéral et de l'emprunt
        uint256 collateralValueUsd = IPriceOracle(priceOracle).assetToUsd(cToken, collateralValue);
        uint256 borrowValueUsd = IPriceOracle(priceOracle).assetToUsd(asset, borrowValue);

        // Vérifier que les valeurs sont non nulles
        require(collateralValueUsd > 0 && borrowValueUsd > 0, "Invalid price values");

        // Health factor = (collatéral * ratio) / emprunt
        // Utiliser une multiplication sécurisée pour éviter l'overflow
        uint256 numerator = collateralValueUsd * collateralRatio;
        require(numerator / collateralValueUsd == collateralRatio, "Overflow in health factor calculation");
        
        return (numerator * HEALTH_FACTOR_PRECISION) / (borrowValueUsd * 10000);
    }

    /**
     * @notice Calcule la liquidité disponible dans la pool
     * @return Montant disponible pour l'emprunt
     */
    function getAvailableLiquidity() public view returns (uint256) {
        return totalDeposits - totalBorrows;
    }

    /**
     * @notice Calcule la limite d'emprunt pour un utilisateur
     * @param user Adresse de l'utilisateur
     * @return Limite d'emprunt en USD
     */
    function getBorrowLimit(address user) public view returns (uint256) {
        if (collateralSupplied[user] == 0) return 0;

        // Obtenir la valeur du collatéral en USD
        uint256 collateralValueUSD = IPriceOracle(priceOracle).assetToUsd(address(cToken), collateralSupplied[user]);
        
        // Calculer la limite d'emprunt basée sur le collatéral
        uint256 borrowLimit = (collateralValueUSD * 10000) / collateralRatio;

        // Obtenir les emprunts existants sur toutes les pools
        LendingPool[] memory userPools = ILendingPoolFactory(factory).getUserPools(user);
        uint256 totalBorrowsUSD = 0;

        for (uint256 i = 0; i < userPools.length; i++) {
            LendingPool pool = userPools[i];
            if (address(pool) != address(this)) {
                uint256 poolBorrows = pool.userBorrows(user);
                if (poolBorrows > 0) {
                    totalBorrowsUSD += IPriceOracle(priceOracle).assetToUsd(pool.asset(), poolBorrows);
                }
            }
        }

        // Soustraire les emprunts existants de la limite
        if (totalBorrowsUSD >= borrowLimit) return 0;
        return borrowLimit - totalBorrowsUSD;
    }

    /**
     * @notice Emprunte des actifs du pool
     * @param amount Montant à emprunter
     */
    function borrow(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= getAvailableLiquidity(), "Insufficient liquidity");
        
        // Vérifier le collatéral
        require(collateralSupplied[msg.sender] > 0, "No collateral supplied");

        // Calculer les frais du protocole
        uint256 protocolFee = _calculateProtocolFee(amount);
        uint256 totalAmount = amount + protocolFee;

        // Mettre à jour temporairement les emprunts pour vérifier le health factor
        userBorrows[msg.sender] += amount;
        uint256 healthFactor = calculateHealthFactor(msg.sender);
        userBorrows[msg.sender] -= amount;  // Remettre à l'état initial
        require(healthFactor >= MIN_HEALTH_FACTOR, "Health factor too low");

        // Vérifier la limite d'emprunt
        require(userBorrows[msg.sender] + amount <= getBorrowLimit(msg.sender), "Borrow limit exceeded");

        // Mettre à jour les emprunts
        totalBorrows += amount;
        userBorrows[msg.sender] += amount;

        // Ajouter les frais du protocole
        _addProtocolFees(protocolFee);

        // Transférer les fonds
        if (asset == address(0)) {
            require(msg.value >= totalAmount, "Insufficient ETH sent");
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
            if (msg.value > totalAmount) {
                (success, ) = msg.sender.call{value: msg.value - totalAmount}("");
                require(success, "ETH refund failed");
            }
        } else {
            IERC20(asset).transfer(msg.sender, amount);
        }

        emit Borrowed(msg.sender, amount, protocolFee);
    }

    /**
     * @notice Remet un emprunt
     * @param amount Montant à rembourser
     */
    function repay(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(userBorrows[msg.sender] >= amount, "Amount exceeds borrowings");

        // Calculer les frais du protocole
        uint256 protocolFee = _calculateProtocolFee(amount);
        uint256 repayAmount = amount + protocolFee;

        // Mettre à jour les emprunts
        userBorrows[msg.sender] -= amount;
        totalBorrows -= amount;
        
        // Ajouter les frais au total des frais du protocole
        protocolFees += protocolFee;

        // Transférer les fonds
        if (asset == address(0)) {
            require(msg.value >= repayAmount, "Insufficient ETH sent");
            if (msg.value > repayAmount) {
                (bool success, ) = msg.sender.call{value: msg.value - repayAmount}("");
                require(success, "ETH refund failed");
            }
        } else {
            require(msg.value == 0, "ETH not accepted for ERC20 repayment");
            IERC20(asset).safeTransferFrom(msg.sender, address(this), repayAmount);
        }

        updateInterestRate();
        emit Repaid(msg.sender, amount, protocolFee);
    }

    /**
     * @notice Reçoit de l'ETH - fonction fallback
     */
    receive() external payable {
        require(asset == address(0), "Not an ETH pool");
    }
}