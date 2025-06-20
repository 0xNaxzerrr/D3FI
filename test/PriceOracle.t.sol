// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/utils/PriceOracle.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockPriceFeed.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;
    MockERC20 public mockToken;
    MockPriceFeed public mockPriceFeed;
    address public alice = address(0x1);

    function setUp() public {
        oracle = new PriceOracle();
        mockToken = new MockERC20("Mock Token", "MTK");
        mockPriceFeed = new MockPriceFeed();
    }

    function testSetPriceFeed() public {
        oracle.setPriceFeed(address(mockToken), address(mockPriceFeed));
        assertEq(oracle.priceFeedSource(address(mockToken)), address(mockPriceFeed));
    }

    function testSetPriceFeedOnlyOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Not authorized");
        oracle.setPriceFeed(address(mockToken), address(mockPriceFeed));
        vm.stopPrank();
    }

    function testGetPrice() public {
        oracle.setPriceFeed(address(mockToken), address(mockPriceFeed));
        mockPriceFeed.setPrice(1e8); // 1 USD
        uint256 price = oracle.getAssetPrice(address(mockToken));
        assertEq(price, 1e8);
    }

    function testGetPriceNoFeed() public {
        vm.expectRevert("Price feed not registered");
        oracle.getAssetPrice(address(mockToken));
    }

    function testAuthorizeCaller() public {
        oracle.authorizeCaller(alice);
        assertTrue(oracle.authorizedCallers(alice));
    }
} 