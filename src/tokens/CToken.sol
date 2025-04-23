// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title CToken
 * @notice Token représentant le collatéral dans une pool de prêt D3FI
 */
contract CToken is ERC20, Ownable {
    address public asset;        // L'actif sous-jacent
    address public lendingPool;  // La pool de prêt associée

    event LendingPoolSet(address indexed lendingPool);

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool, "CToken: caller is not the lending pool");
        _;
    }

    /**
     * @notice Crée un nouveau token de collatéral
     * @param name Nom du token (ex: "D3FI ETH Collateral")
     * @param symbol Symbole du token (ex: "cETH")
     * @param _asset Adresse de l'actif sous-jacent (address(0) pour ETH)
     */
    constructor(
        string memory name,
        string memory symbol,
        address _asset
    ) ERC20(name, symbol) {
        asset = _asset;
    }

    /**
     * @notice Définit l'adresse de la pool de prêt
     * @dev Ne peut être appelé qu'une fois
     * @param _lendingPool L'adresse de la pool de prêt
     */
    function setLendingPool(address _lendingPool) external onlyOwner {
        require(lendingPool == address(0), "LendingPool already set");
        require(_lendingPool != address(0), "Invalid LendingPool address");

        lendingPool = _lendingPool;

        // Transférer la propriété à la pool de prêt
        transferOwnership(_lendingPool);

        emit LendingPoolSet(_lendingPool);
    }

    /**
     * @notice Frappe de nouveaux tokens pour un utilisateur
     * @dev Seule la pool de prêt peut appeler cette fonction
     * @param user L'adresse qui recevra les tokens
     * @param amount Le montant de tokens à frapper
     */
    function mint(address user, uint256 amount) external onlyLendingPool {
        _mint(user, amount);
    }

    /**
     * @notice Brûle des tokens d'un utilisateur
     * @dev Seule la pool de prêt peut appeler cette fonction
     * @param user L'adresse dont les tokens seront brûlés
     * @param amount Le montant de tokens à brûler
     */
    function burn(address user, uint256 amount) external onlyLendingPool {
        _burn(user, amount);
    }
}