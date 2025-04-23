// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

interface IToken {
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;
}
