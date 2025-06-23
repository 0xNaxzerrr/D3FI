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

    function testUpdateParametersRevertIfMinRateNotLessThanMaxRate() public {
        vm.expectRevert("Min must be < max");
        model.updateParameters(
            200,    // baseRate
            300,    // slopeRate1
            500,    // slopeRate2
            7000,   // optimalUtilizationRate
            2500,   // minRate >= maxRate
            2500    // maxRate
        );
    }

    function testUpdateParametersRevertIfOptimalUtilizationRateAbove100Percent() public {
        vm.expectRevert("Rate must be <= 100%");
        model.updateParameters(
            200,    // baseRate
            300,    // slopeRate1
            500,    // slopeRate2
            10001,  // optimalUtilizationRate > 10000
            100,    // minRate
            2500    // maxRate
        );
    }

    function testCalculateInterestRateReturnsMinRateIfBelowMin() public {
        // Avec une minRate très haute, le taux calculé sera en dessous
        InterestRateModel m = new InterestRateModel(
            100,    // baseRate
            200,    // slopeRate1
            400,    // slopeRate2
            8000,   // optimalUtilizationRate
            2000,   // minRate (20%)
            5000    // maxRate (50%)
        );
        uint256 rate = m.calculateInterestRate(1000); // Faible utilisation
        assertEq(rate, 2000); // minRate
    }

    function testCalculateInterestRateReturnsMaxRateIfAboveMax() public {
        // Avec un maxRate très bas, le taux calculé sera au-dessus
        InterestRateModel m = new InterestRateModel(
            100,    // baseRate
            200,    // slopeRate1
            400,    // slopeRate2
            8000,   // optimalUtilizationRate
            50,     // minRate (0.5%)
            300     // maxRate (3%)
        );
        uint256 rate = m.calculateInterestRate(10000); // Utilisation maximale
        assertEq(rate, 300); // maxRate
    }
} 