// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/core/InterestRateModel.sol";

contract InterestRateModelTest is Test {
    InterestRateModel public model;
    address public alice = address(0x1);

    function setUp() public {
        model = new InterestRateModel(
            100,    // baseRate: 1%
            200,    // slopeRate1: 2%
            400,    // slopeRate2: 4%
            8000,   // optimalUtilizationRate: 80%
            50,     // minRate: 0.5%
            2000    // maxRate: 20%
        );
    }

    function testCalculateInterestRateBelowOptimal() public view {
        uint256 rate = model.calculateInterestRate(5000); // 50%
        assertTrue(rate > 0);
    }

    function testCalculateInterestRateAtOptimal() public view {
        uint256 rate = model.calculateInterestRate(8000); // 80%
        assertTrue(rate > 0);
    }

    function testCalculateInterestRateAboveOptimal() public view {
        uint256 rate = model.calculateInterestRate(9000); // 90%
        assertTrue(rate > 0);
    }

    function testUpdateParameters() public {
        model.updateParameters(
            200,    // baseRate: 2%
            300,    // slopeRate1: 3%
            500,    // slopeRate2: 5%
            7000,   // optimalUtilizationRate: 70%
            100,    // minRate: 1%
            2500    // maxRate: 25%
        );
        uint256 rate = model.calculateInterestRate(8000);
        assertTrue(rate > 0);
    }

    function testUpdateParametersOnlyOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        model.updateParameters(
            200,    // baseRate
            300,    // slopeRate1
            500,    // slopeRate2
            7000,   // optimalUtilizationRate
            100,    // minRate
            2500    // maxRate
        );
        vm.stopPrank();
    }
} 