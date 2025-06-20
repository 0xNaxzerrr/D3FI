// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/core/LendingPoolFactory.sol";
import "../src/core/LendingPool.sol";
import "../src/tokens/CToken.sol";
import "../src/core/InterestRateModel.sol";
import "../src/utils/PriceOracle.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockPriceFeed.sol";
import "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract LendingPoolFactoryTest is Test {
    LendingPoolFactory public factory;
    PriceOracle public oracle;
    MockERC20 public mockToken;
    MockPriceFeed public mockPriceFeed;
    InterestRateModel public interestRateModel;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public owner = address(this);

    // Adresses simulées pour les tests
    address constant _ETH_ADDRESS = address(0);
    address constant _MOCK_DAI = address(0x1);
    address constant _MOCK_PRICE_FEED_ETH = address(0x100);
    address constant _MOCK_PRICE_FEED_DAI = address(0x101);

    function setUp() public {
        // Déployer l'oracle d'abord
        oracle = new PriceOracle();
        // Déployer la factory avec l'oracle
        factory = new LendingPoolFactory(address(oracle));
        mockToken = new MockERC20("Mock Token", "MTK");
        mockPriceFeed = new MockPriceFeed();

        // Configurer l'oracle
        oracle.authorizeCaller(address(factory));
        oracle.setPriceFeed(address(mockToken), address(mockPriceFeed));
        mockPriceFeed.setPrice(1e8); // 1 USD

        // Mint des tokens pour les tests
        mockToken.mint(alice, 2_000_000e18);
        mockToken.mint(bob, 2_000_000e18);

        // Labels pour le debug
        vm.label(address(factory), "Factory");
        vm.label(address(oracle), "Oracle");
        vm.label(address(mockToken), "Mock Token");
        vm.label(address(mockPriceFeed), "Mock Price Feed");
    }

    function _createPool() internal returns (LendingPool, CToken) {
        address payable poolAddress = payable(factory.createPool(
            address(mockToken),
            "Mock Token",
            "MTK",
            15000, // 150% ratio
            address(mockPriceFeed)
        ));
        LendingPool _pool = LendingPool(poolAddress);
        CToken _cToken = CToken(_pool.cToken());
        oracle.setPriceFeed(address(_cToken), address(mockPriceFeed));
        return (_pool, _cToken);
    }

    function testProtocolFees() public {
        // Create a pool
        address payable poolAddress = payable(factory.createPool(
            address(mockToken),
            "Mock Token",
            "MTK",
            15000,
            address(mockPriceFeed)
        ));
        LendingPool pool = LendingPool(poolAddress);
        CToken cToken = CToken(pool.cToken());

        // Register price feed for cToken
        oracle.setPriceFeed(address(cToken), address(mockPriceFeed));

        // Alice deposits tokens for liquidity
        vm.startPrank(alice);
        mockToken.approve(address(pool), 1_000_000e18);
        pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob borrows to generate fees
        vm.startPrank(bob);
        mockToken.approve(address(pool), 1_000_000e18);
        pool.deposit(1_000_000e18);
        cToken.approve(address(pool), 500_000e18);
        pool.supplyCollateral(500_000e18);
        pool.borrow(100_000e18);
        vm.stopPrank();

        // Calculate expected fees (0.5% of 100_000e18)
        uint256 expectedFees = (100_000e18 * factory.getProtocolFeeRate()) / 10000;
        assertEq(pool.protocolFees(), expectedFees, "Incorrect fees");

        // Collect fees as factory owner
        vm.startPrank(address(factory));
        pool.collectProtocolFees();
        assertEq(pool.protocolFees(), 0, "Fees not collected");
        assertEq(mockToken.balanceOf(address(factory)), expectedFees, "Fees not transferred to owner");
        vm.stopPrank();
    }

    function testCollectAllProtocolFees() public {
        // Create two pools with different tokens
        MockERC20 mockToken2 = new MockERC20("Mock Token 2", "MTK2");
        mockToken2.mint(alice, 2_000_000e18);
        mockToken2.mint(bob, 2_000_000e18);
        oracle.setPriceFeed(address(mockToken2), address(mockPriceFeed));

        // Create first pool
        (LendingPool pool1, CToken cToken1) = _createPool();
        
        // Create second pool with different token
        address payable poolAddress2 = payable(factory.createPool(
            address(mockToken2),
            "Mock Token 2",
            "MTK2",
            15000,
            address(mockPriceFeed)
        ));
        LendingPool pool2 = LendingPool(poolAddress2);
        CToken cToken2 = CToken(pool2.cToken());
        oracle.setPriceFeed(address(cToken2), address(mockPriceFeed));

        // Alice deposits in both pools
        vm.startPrank(alice);
        mockToken.approve(address(pool1), 1_000_000e18);
        mockToken2.approve(address(pool2), 1_000_000e18);
        pool1.deposit(1_000_000e18);
        pool2.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob borrows from both pools
        vm.startPrank(bob);
        mockToken.approve(address(pool1), 1_000_000e18);
        mockToken2.approve(address(pool2), 1_000_000e18);
        pool1.deposit(1_000_000e18);
        pool2.deposit(1_000_000e18);
        cToken1.approve(address(pool1), 500_000e18);
        cToken2.approve(address(pool2), 500_000e18);
        pool1.supplyCollateral(500_000e18);
        pool2.supplyCollateral(500_000e18);
        pool1.borrow(50_000e18);
        pool2.borrow(50_000e18);
        vm.stopPrank();

        // Calculate expected fees
        uint256 expectedFees1 = (50_000e18 * factory.getProtocolFeeRate()) / 10000;
        uint256 expectedFees2 = (50_000e18 * factory.getProtocolFeeRate()) / 10000;

        // Check accumulated fees
        assertEq(pool1.protocolFees(), expectedFees1, "Incorrect fees for pool1");
        assertEq(pool2.protocolFees(), expectedFees2, "Incorrect fees for pool2");

        // Collect all fees as factory owner
        vm.startPrank(address(this)); // Test contract is factory owner
        factory.collectAllProtocolFees();
        assertEq(pool1.protocolFees(), 0, "Fees not collected from pool1");
        assertEq(pool2.protocolFees(), 0, "Fees not collected from pool2");
        assertEq(mockToken.balanceOf(address(factory)), expectedFees1, "Fees not transferred to owner for pool1");
        assertEq(mockToken2.balanceOf(address(factory)), expectedFees2, "Fees not transferred to owner for pool2");
        vm.stopPrank();
    }

    function testOnlyOwnerCanCollectAllFees() public {
        (LendingPool pool, CToken cToken) = _createPool();
        // Alice dépose et fournit du collatéral
        vm.startPrank(alice);
        mockToken.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        pool.borrow(200e18);
        vm.stopPrank();

        // Bob tente de collecter les frais
        vm.startPrank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.collectAllProtocolFees();
        vm.stopPrank();
    }

    function testUpdateProtocolFeeRate() public {
        assertEq(factory.getProtocolFeeRate(), 50);
        factory.updateProtocolFeeRate(100);
        assertEq(factory.getProtocolFeeRate(), 100);

        vm.expectRevert("Fee rate too high");
        factory.updateProtocolFeeRate(1001);
    }

    function testRepayWithFees() public {
        (LendingPool _pool, CToken _cToken) = _createPool();

        // Alice dépose
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1000e18);
        _pool.deposit(1000e18);
        vm.stopPrank();

        // Bob dépose, fournit du collatéral et emprunte
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1000e18);
        _pool.deposit(1000e18);
        _cToken.approve(address(_pool), 500e18);
        _pool.supplyCollateral(500e18);
        _pool.borrow(200e18);

        // Calculate expected fees for borrow
        uint256 borrowFees = (200e18 * _pool.protocolFeeRate()) / 10000;
        assertEq(_pool.protocolFees(), borrowFees, "Incorrect borrow fees");

        // Bob rembourse
        mockToken.approve(address(_pool), type(uint256).max);
        _pool.repay(200e18);

        // Calculate expected fees for repayment
        uint256 repayFees = (200e18 * _pool.protocolFeeRate()) / 10000;
        uint256 totalExpectedFees = borrowFees + repayFees;
        assertEq(_pool.protocolFees(), totalExpectedFees, "Incorrect total fees");
        vm.stopPrank();
    }

    function testCreateEthPool() public {
        oracle.setPriceFeed(_ETH_ADDRESS, address(mockPriceFeed));
        factory.createPool(
            _ETH_ADDRESS,
            "Ethereum",
            "ETH",
            15000,
            _MOCK_PRICE_FEED_ETH
        );

        address payable ethPoolAddress = payable(factory.assetToPools(_ETH_ADDRESS));
        assertTrue(ethPoolAddress != address(0));

        address[] memory allPools = factory.getAllPools();
        assertEq(allPools.length, 1);
        assertEq(allPools[0], ethPoolAddress);

        LendingPool ethPool = LendingPool(ethPoolAddress);
        assertEq(ethPool.asset(), _ETH_ADDRESS);
        assertEq(ethPool.collateralRatio(), 15000);
    }

    function testCreateErc20Pool() public {
        oracle.setPriceFeed(_MOCK_DAI, address(mockPriceFeed));
        factory.createPool(
            _MOCK_DAI,
            "DAI Stablecoin",
            "DAI",
            12500,
            _MOCK_PRICE_FEED_DAI
        );

        address payable daiPoolAddress = payable(factory.assetToPools(_MOCK_DAI));
        assertTrue(daiPoolAddress != address(0));

        LendingPool daiPool = LendingPool(daiPoolAddress);
        assertEq(daiPool.asset(), _MOCK_DAI);
        assertEq(daiPool.collateralRatio(), 12500);
    }

    function testCreatePoolWithInvalidToken() public {
        vm.expectRevert("Price feed not registered");
        factory.createPool(address(0), "Mock Token", "MTK", 15000, address(mockPriceFeed));
    }

    function testCreatePoolWithInvalidPriceFeed() public {
        vm.expectRevert("Price feed address cannot be zero");
        factory.createPool(address(mockToken), "Mock Token", "MTK", 15000, address(0));
    }

    function testCreatePoolWithInvalidCollateralRatio() public {
        vm.expectRevert("Collateral ratio must be >= 100%");
        factory.createPool(address(mockToken), "Mock Token", "MTK", 9999, address(mockPriceFeed));
    }

    function testCreatePoolWithExistingToken() public {
        factory.createPool(address(mockToken), "Mock Token", "MTK", 15000, address(mockPriceFeed));
        vm.expectRevert("Pool already exists for this asset");
        factory.createPool(address(mockToken), "Mock Token", "MTK", 15000, address(mockPriceFeed));
    }

    function testGetPool() public {
        (LendingPool _pool,) = _createPool();
        address poolAddress = factory.getPool(address(mockToken));
        assertEq(poolAddress, address(_pool));
    }

    function testGetPoolNonExistent() public view {
        address poolAddress = factory.getPool(address(0x123));
        assertEq(poolAddress, address(0));
    }

    function testGetAllPools() public {
        (LendingPool _pool1,) = _createPool();
        
        // Créer une deuxième pool
        MockERC20 mockToken2 = new MockERC20("Mock Token 2", "MTK2");
        oracle.setPriceFeed(address(mockToken2), address(mockPriceFeed));
        address payable poolAddress2 = payable(factory.createPool(
            address(mockToken2),
            "Mock Token 2",
            "MTK2",
            15000,
            address(mockPriceFeed)
        ));
        LendingPool _pool2 = LendingPool(poolAddress2);

        address[] memory pools = factory.getAllPools();
        assertEq(pools.length, 2);
        assertEq(pools[0], address(_pool1));
        assertEq(pools[1], address(_pool2));
    }

    function testGetAllPoolsEmpty() public view {
        address[] memory pools = factory.getAllPools();
        assertEq(pools.length, 0);
    }

    function testUpdateProtocolFeeRateOnlyOwner() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.updateProtocolFeeRate(100);
        vm.stopPrank();
    }

    function testUpdateProtocolFeeRateInvalid() public {
        vm.expectRevert("Fee rate too high");
        factory.updateProtocolFeeRate(1001);
    }

    function testUpdateProtocolFeeRateZero() public {
        factory.updateProtocolFeeRate(0);
        assertEq(factory.getProtocolFeeRate(), 0);
    }
}