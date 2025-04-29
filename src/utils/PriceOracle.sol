// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title PriceOracle
 * @notice Gère les price feeds Chainlink pour les actifs du protocole
 */
contract PriceOracle is Ownable {
    // Mapping token address => price feed address
    mapping(address => address) public priceFeedSource;

    // ETH est représenté par address(0)
    // USD est la devise de référence

    event PriceFeedSet(address indexed asset, address indexed source);

    /**
     * @notice Définit ou met à jour le price feed pour un actif
     * @param asset Adresse du token (address(0) pour ETH)
     * @param priceFeed Adresse du price feed Chainlink
     */
    function setPriceFeed(address asset, address priceFeed) external onlyOwner {
        require(priceFeed != address(0), "Invalid price feed address");
        priceFeedSource[asset] = priceFeed;
        emit PriceFeedSet(asset, priceFeed);
    }

    /**
     * @notice Obtient le dernier prix d'un actif en USD, avec 8 décimales
     * @param asset Adresse du token (address(0) pour ETH)
     * @return Le prix en USD avec 8 décimales
     */
    function getAssetPrice(address asset) external view returns (uint256) {
        address feedAddress = priceFeedSource[asset];
        require(feedAddress != address(0), "Price feed not registered");

        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Price must be positive");

        return uint256(price);
    }

    /**
     * @notice Convertit un montant d'un actif en valeur USD
     * @param asset Adresse du token
     * @param amount Montant de l'actif
     * @return La valeur en USD avec 8 décimales
     */
    function assetToUsd(address asset, uint256 amount) external view returns (uint256) {
        uint256 price = this.getAssetPrice(asset);
        // Ajustement pour 18 décimales des jetons -> 8 décimales pour USD
        return (amount * price) / 1e18;
    }
}