// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/core/LendingPool.sol";
import "../src/core/LendingPoolFactory.sol";
import "../src/tokens/CToken.sol";
import "../src/core/InterestRateModel.sol";
import "../src/utils/PriceOracle.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockPriceFeed.sol";

contract LendingPoolTest is Test {
    LendingPoolFactory public factory;
    LendingPool public pool;
    CToken public cToken;
    InterestRateModel public interestRateModel;
    PriceOracle public oracle;
    MockERC20 public mockToken;
    MockPriceFeed public mockPriceFeed;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public owner = address(this);

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
        // Enregistrer le price feed pour l'ETH simulé si besoin
        oracle.setPriceFeed(address(0), address(mockPriceFeed));

        // Mint des tokens pour les tests
        mockToken.mint(alice, 2_000_000e18);
        mockToken.mint(bob, 2_000_000e18);
    }

    function _createPoolAndCToken() internal returns (LendingPool, CToken) {
        address payable poolAddress = payable(factory.createPool(
            address(mockToken),
            "Mock Token",
            "MTK",
            15000, // 150% de ratio de collatéral
            address(mockPriceFeed)
        ));
        LendingPool _pool = LendingPool(poolAddress);
        CToken _cToken = CToken(_pool.cToken());
        // Enregistrer le price feed pour le cToken
        oracle.setPriceFeed(address(_cToken), address(mockPriceFeed));
        return (_pool, _cToken);
    }

    function testHealthFactor() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et emprunte
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);

        // Vérifier le health factor avant emprunt
        uint256 healthFactorBefore = _pool.calculateHealthFactor(bob);
        assertEq(healthFactorBefore, type(uint256).max); // Pas d'emprunt

        // Emprunter
        _pool.borrow(200_000e18);

        // Vérifier le health factor après emprunt
        uint256 healthFactorAfter = _pool.calculateHealthFactor(bob);
        assertGt(healthFactorAfter, 1e18); // Doit être > 1.0
        vm.stopPrank();
    }

    function testInterestRateUpdate() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et emprunte
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        _pool.borrow(200_000e18);
        vm.stopPrank();

        // Vérifier que le taux d'intérêt a été mis à jour
        uint256 interestRate = _pool.currentInterestRate();
        assertGt(interestRate, 0);
    }

    function testRevertWhenBorrowWithLowHealthFactor() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et tente d'emprunter trop
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 100_000e18);
        _pool.supplyCollateral(100_000e18);

        // Cette opération devrait échouer car le health factor serait trop bas
        vm.expectRevert("Health factor too low");
        _pool.borrow(500_000e18);
        vm.stopPrank();
    }

    function testWithdrawCollateral() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        
        // Bob fournit du collatéral
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        
        // Retirer une partie du collatéral
        _pool.withdrawCollateral(200_000e18);
        assertEq(_pool.collateralSupplied(bob), 300_000e18);
        vm.stopPrank();
    }

    function testRevertWithdrawCollateralInsufficient() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        
        vm.expectRevert("Insufficient collateral");
        _pool.withdrawCollateral(600_000e18);
        vm.stopPrank();
    }

    function testRevertWithdrawCollateralBreachRatio() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et emprunte
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        _pool.borrow(200_000e18);
        
        // Tenter de retirer trop de collatéral
        vm.expectRevert("Would breach collateral ratio");
        _pool.withdrawCollateral(400_000e18);
        vm.stopPrank();
    }

    function testRepay() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob emprunte
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        _pool.borrow(200_000e18);
        
        // Rembourser une partie
        mockToken.approve(address(_pool), 300_000e18); // Approbation plus grande pour couvrir les intérêts
        _pool.repay(100_000e18);
        assertEq(_pool.userBorrows(bob), 100_000e18);
        vm.stopPrank();
    }

    function testRevertRepayExceedsBorrowings() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob emprunte
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        _pool.borrow(200_000e18);
        
        // Tenter de rembourser plus que l'emprunt
        mockToken.approve(address(_pool), 300_000e18);
        vm.expectRevert("Amount exceeds borrowings");
        _pool.repay(300_000e18);
        vm.stopPrank();
    }

    function testUpdateCollateralRatio() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        // Mettre à jour le ratio de collatéral
        _pool.updateCollateralRatio(20000); // 200%
        assertEq(_pool.collateralRatio(), 20000);
    }

    function testRevertUpdateCollateralRatioTooLow() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        vm.expectRevert("Ratio must be at least 100%");
        _pool.updateCollateralRatio(9999);
    }

    function testUpdateInterestRateModel() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        // Créer un nouveau modèle
        InterestRateModel newModel = new InterestRateModel(
            200,    // baseRate: 2%
            300,    // slopeRate1: 3%
            500,    // slopeRate2: 5%
            7000,   // optimalUtilizationRate: 70%
            100,    // minRate: 1%
            2500    // maxRate: 25%
        );
        
        // Mettre à jour le modèle
        _pool.updateInterestRateModel(address(newModel));
        assertEq(_pool.interestRateModel(), address(newModel));
    }

    function testRevertUpdateInterestRateModelInvalidAddress() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        vm.expectRevert("Invalid address");
        _pool.updateInterestRateModel(address(0));
    }

    function testUpdateProtocolFeeRate() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        _pool.updateProtocolFeeRate(100); // 1%
        assertEq(_pool.protocolFeeRate(), 100);
    }

    function testRevertUpdateProtocolFeeRateTooHigh() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        vm.expectRevert("Fee rate too high");
        _pool.updateProtocolFeeRate(1001); // > 10%
    }

    function testCollectProtocolFees() public {
        (LendingPool _pool, CToken _cToken) = _createPoolAndCToken();
        
        // Alice dépose des tokens
        vm.startPrank(alice);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        vm.stopPrank();

        // Bob emprunte (génère des frais)
        vm.startPrank(bob);
        mockToken.approve(address(_pool), 1_000_000e18);
        _pool.deposit(1_000_000e18);
        _cToken.approve(address(_pool), 500_000e18);
        _pool.supplyCollateral(500_000e18);
        _pool.borrow(200_000e18);
        vm.stopPrank();

        // Collecter les frais
        uint256 balanceBefore = mockToken.balanceOf(owner);
        _pool.collectProtocolFees();
        uint256 balanceAfter = mockToken.balanceOf(owner);
        assertGt(balanceAfter, balanceBefore);
    }

    function testRevertCollectProtocolFeesNoFees() public {
        (LendingPool _pool,) = _createPoolAndCToken();
        
        vm.expectRevert("No fees to collect");
        _pool.collectProtocolFees();
    }
}