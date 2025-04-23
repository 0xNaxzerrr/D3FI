// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IInterestRateModel.sol";
import "../interfaces/IToken.sol";

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

    // Paramètres de la pool
    uint256 public collateralRatio;    // Ratio de collatéral (ex: 15000 = 150%)
    uint256 public currentInterestRate; // Taux d'intérêt actuel

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
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event CollateralSupplied(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

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
        uint256 _collateralRatio
    ) {
        require(_collateralRatio >= 10000, "Collateral ratio must be >= 100%");

        asset = _asset;
        cToken = _cToken;
        interestRateModel = _interestRateModel;
        collateralRatio = _collateralRatio;
        lastUpdateTimestamp = block.timestamp;

        // Initialiser avec un taux par défaut
        currentInterestRate = 500; // 5%

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
     * @notice Dépose des actifs dans la pool
     * @param amount Montant à déposer
     */
    function deposit(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be > 0");

        // Traitement différent pour ETH vs ERC20
        if (asset == address(0)) {
            require(msg.value == amount, "Incorrect ETH value");
        } else {
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
     * @notice Emprunte des actifs contre le collatéral fourni
     * @param amount Montant à emprunter
     */
    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(amount <= totalDeposits - totalBorrows, "Not enough liquidity");

        // Vérifier que l'utilisateur a assez de collatéral
        uint256 newBorrowTotal = userBorrows[msg.sender] + amount;
        uint256 requiredCollateral = (newBorrowTotal * collateralRatio) / 10000;

        require(collateralSupplied[msg.sender] >= requiredCollateral, "Insufficient collateral");

        // Mettre à jour les données d'emprunt
        userBorrows[msg.sender] += amount;
        totalBorrows += amount;

        // Transférer les actifs à l'utilisateur
        if (asset == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }

        updateInterestRate();
        emit Borrowed(msg.sender, amount);
    }

    /**
     * @notice Rembourse un emprunt
     * @param amount Montant à rembourser
     */
    function repay(uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(userBorrows[msg.sender] >= amount, "Amount exceeds debt");

        // Traitement différent pour ETH vs ERC20
        if (asset == address(0)) {
            require(msg.value == amount, "Incorrect ETH value");
        } else {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }

        // Mettre à jour les données d'emprunt
        userBorrows[msg.sender] -= amount;
        totalBorrows -= amount;

        updateInterestRate();
        emit Repaid(msg.sender, amount);
    }

    /**
     * @notice Reçoit de l'ETH - fonction fallback
     */
    receive() external payable {
        require(asset == address(0), "Not an ETH pool");
    }
}