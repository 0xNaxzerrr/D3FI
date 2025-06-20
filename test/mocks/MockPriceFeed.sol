// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockPriceFeed
 * @notice Simule un price feed Chainlink pour les tests
 */
contract MockPriceFeed is AggregatorV3Interface {
    uint8 private constant _DECIMALS = 8;
    uint80 private _roundId = 1;
    int256 private _price = 1e8; // 1 USD par défaut
    uint256 private _timestamp = block.timestamp;
    uint80 private _answeredInRound = 1;

    /**
     * @notice Retourne les dernières données de prix (similaire à Chainlink)
     * @return roundId ID du dernier tour
     * @return answer Prix actuel
     * @return startedAt Timestamp du début
     * @return updatedAt Timestamp de la dernière mise à jour
     * @return answeredInRound Tour dans lequel la réponse a été fournie
     */
    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (_roundId, _price, _timestamp, _timestamp, _answeredInRound);
    }

    /**
     * @notice Définit le prix pour les tests
     * @param newPrice Nouveau prix (avec 8 décimales)
     */
    function setPrice(uint256 newPrice) external {
        require(newPrice > 0, "Price must be greater than 0");
        _price = int256(newPrice);
        _timestamp = block.timestamp;
        _roundId++;
        _answeredInRound = _roundId;
    }

    /**
     * @notice Retourne le nombre de décimales du price feed
     */
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @notice Retourne la description du price feed
     */
    function description() external pure override returns (string memory) {
        return "Mock Price Feed";
    }

    /**
     * @notice Retourne la version du price feed
     */
    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _id) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (_id, _price, _timestamp, _timestamp, _answeredInRound);
    }
}