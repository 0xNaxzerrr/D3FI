// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Token ERC20 simple pour les tests
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice Crée des tokens pour les tests
     * @param to Adresse recevant les tokens
     * @param amount Montant à créer
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Brûle des tokens pour les tests
     * @param from Adresse dont les tokens sont brûlés
     * @param amount Montant à brûler
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    /**
     * @notice Décimales du token (18 par défaut)
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}