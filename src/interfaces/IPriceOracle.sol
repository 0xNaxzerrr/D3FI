// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

interface IPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function assetToUsd(address asset, uint256 amount) external view returns (uint256);
    function setPriceFeed(address asset, address priceFeed) external;
    function priceFeedSource(address asset) external view returns (address);
}