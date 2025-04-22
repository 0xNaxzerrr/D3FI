// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IInterestRateModel {
    function calculateInterestRate(uint256 utilizationRatio) external view returns (uint256);
}

interface IToken {
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;
}

/**
 * @title LendingPool
 * @notice Gère les opérations de prêt et d'emprunt pour un actif spécifique
 */
contract LendingPool is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Adresses des contrats liés
    address public asset;              // Token sous-jacent (address(0) pour ETH)
    address public aToken;             // Token de dépôt
    address public cToken;             // Token de collatéral
    address public interestRateModel;  // Modèle de taux d'intérêt

    // Paramètres de la pool
    uint256 public collateralRatio;    // Ratio de collatéral (ex: 15000 = 150%)
    uint256 public currentInterestRate; // Taux d'intérêt actuel

    // Variables d'état
    uint256 public totalDeposits;      // Total des actifs déposés
    uint256 public totalBorrows;       // Total des actifs empruntés
    uint256 public lastUpdateTimestamp; // Dernière mise à jour des intérêts

    // Structure pour les emprunteurs
    struct BorrowerInfo {
        uint256 principal;            // Montant emprunté
        uint256 interestIndex;        // Indice d'intérêt au moment de l'emprunt
        uint256 lastUpdateTimestamp;  // Dernière mise à jour
    }

    // Mapping des emprunteurs
    mapping(address => BorrowerInfo) public borrowers;

    // Événements
    event PoolInitialized(address indexed asset, address aToken, address cToken, address interestRateModel);
    event InterestRateUpdated(uint256 utilizationRate, uint256 newRate);
    event CollateralRatioUpdated(uint256 newRatio);

    /**
     * @notice Initialise une nouvelle pool de prêt
     * @param _asset Adresse du token sous-jacent (address(0) pour ETH)
     * @param _aToken Adresse du token de dépôt
     * @param _cToken Adresse du token de collatéral
     * @param _interestRateModel Adresse du modèle de taux d'intérêt
     * @param _collateralRatio Ratio de collatéral initial (ex: 15000 = 150%)
     */
    constructor(
        address _asset,
        address _aToken,
        address _cToken,
        address _interestRateModel,
        uint256 _collateralRatio
    ) {
        require(_collateralRatio >= 10000, "Collateral ratio must be >= 100%");

        asset = _asset;
        aToken = _aToken;
        cToken = _cToken;
        interestRateModel = _interestRateModel;
        collateralRatio = _collateralRatio;
        lastUpdateTimestamp = block.timestamp;

        // Initialiser avec un taux par défaut
        currentInterestRate = 500; // 5%

        emit PoolInitialized(_asset, _aToken, _cToken, _interestRateModel);
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
}