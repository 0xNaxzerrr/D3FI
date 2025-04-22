// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AToken
 * @notice Token représentant les dépôts dans le protocole D3FI
 */
contract AToken is ERC20, Ownable {
    address public asset;           // L'actif sous-jacent
    address public lendingPool;     // La pool de prêt associée

    event LendingPoolSet(address indexed lendingPool);

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool, "AToken: caller is not the lending pool");
        _;
    }

    constructor(string memory name, string memory symbol, address _asset)
    ERC20(name, symbol)
    {
        asset = _asset;
    }

    function setLendingPool(address _lendingPool) external onlyOwner {
        require(lendingPool == address(0), "LendingPool already set");
        require(_lendingPool != address(0), "Invalid LendingPool address");

        lendingPool = _lendingPool;
        transferOwnership(_lendingPool);

        emit LendingPoolSet(_lendingPool);
    }

    function mint(address user, uint256 amount) external onlyLendingPool {
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) external onlyLendingPool {
        _burn(user, amount);
    }
}