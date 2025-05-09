// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/tokens/CToken.sol";
import "./mocks/MockERC20.sol";

contract CTokenTest is Test {
    CToken public cToken;
    MockERC20 public mockToken;
    address public lendingPool;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        mockToken = new MockERC20("Mock Token", "MTK");
        cToken = new CToken(
            "Mock cToken",
            "mcMTK",
            address(mockToken)
        );
        lendingPool = address(0x3);
        cToken.setLendingPool(lendingPool);
    }

    function testMint() public {
        vm.startPrank(lendingPool);
        cToken.mint(alice, 100e18);
        assertEq(cToken.balanceOf(alice), 100e18);
        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(lendingPool);
        cToken.mint(alice, 100e18);
        cToken.burn(alice, 50e18);
        assertEq(cToken.balanceOf(alice), 50e18);
        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(lendingPool);
        cToken.mint(alice, 100e18);
        vm.stopPrank();
        
        vm.startPrank(alice);
        cToken.transfer(bob, 50e18);
        assertEq(cToken.balanceOf(alice), 50e18);
        assertEq(cToken.balanceOf(bob), 50e18);
        vm.stopPrank();
    }

    function testTransferFrom() public {
        vm.startPrank(lendingPool);
        cToken.mint(alice, 100e18);
        vm.stopPrank();
        
        vm.startPrank(alice);
        cToken.approve(bob, 50e18);
        vm.stopPrank();
        
        vm.startPrank(bob);
        cToken.transferFrom(alice, bob, 50e18);
        assertEq(cToken.balanceOf(alice), 50e18);
        assertEq(cToken.balanceOf(bob), 50e18);
        vm.stopPrank();
    }

    function testApprove() public {
        vm.startPrank(alice);
        cToken.approve(bob, 50e18);
        assertEq(cToken.allowance(alice, bob), 50e18);
        vm.stopPrank();
    }

    function testName() public view {
        assertEq(cToken.name(), "Mock cToken");
    }

    function testSymbol() public view {
        assertEq(cToken.symbol(), "mcMTK");
    }

    function testDecimals() public view {
        assertEq(cToken.decimals(), 18);
    }
} 