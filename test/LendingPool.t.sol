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

contract RejectETH {
    fallback() external payable { revert("No ETH"); }
}

contract TestLendingPool is LendingPool {
    constructor(
        address _asset,
        address _cToken,
        address _interestRateModel,
        address _priceOracle,
        uint256 _collateralRatio
    ) LendingPool(_asset, _cToken, _interestRateModel, _priceOracle, _collateralRatio) {}

    function addProtocolFees(uint256 amount) public {
        _addProtocolFees(amount);
    }
}

contract LendingPoolTest is Test {
    LendingPool public pool;
    LendingPoolFactory public factory;
    CToken public cToken;
    MockERC20 public token;
    MockPriceFeed public mockPriceFeed;
    PriceOracle public priceOracle;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public owner = address(this);

    function setUp() public {
        // Déployer les contrats
        token = new MockERC20("Test Token", "TEST");
        mockPriceFeed = new MockPriceFeed();
        priceOracle = new PriceOracle();
        
        // Déployer la factory
        factory = new LendingPoolFactory(address(priceOracle));
        
        // Autoriser l'appelant et la factory
        priceOracle.authorizeCaller(address(this));
        priceOracle.authorizeCaller(address(factory));
        
        // Configurer les prix
        mockPriceFeed.setPrice(1e18); // Prix initial à 1 USD
        priceOracle.setPriceFeed(address(token), address(mockPriceFeed));
        
        // Créer une pool
        pool = LendingPool(payable(factory.createPool(
            address(token),
            "Test Token",
            "TEST",
            15000,
            address(mockPriceFeed)
        )));
        
        // Obtenir le CToken associé
        cToken = CToken(pool.cToken());
        
        // Enregistrer le price feed pour le CToken
        priceOracle.setPriceFeed(address(cToken), address(mockPriceFeed));
        
        // Donner des tokens aux utilisateurs de test
        token.mint(alice, 1000e18);
        token.mint(bob, 1000e18);
    }

    function testHealthFactor() public {
        // Alice dépose des tokens
        vm.startPrank(alice);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et emprunte
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);

        // Vérifier le health factor avant emprunt
        uint256 healthFactorBefore = pool.calculateHealthFactor(bob);
        assertEq(healthFactorBefore, type(uint256).max); // Pas d'emprunt

        // Emprunter
        pool.borrow(200e18);

        // Vérifier le health factor après emprunt
        uint256 healthFactorAfter = pool.calculateHealthFactor(bob);
        assertGt(healthFactorAfter, 1e18); // Doit être > 1.0
        vm.stopPrank();
    }

    function testInterestRateUpdate() public {
        // Alice dépose des tokens
        vm.startPrank(alice);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et emprunte
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        pool.borrow(200e18);
        vm.stopPrank();

        // Vérifier que le taux d'intérêt a été mis à jour
        uint256 interestRate = pool.currentInterestRate();
        assertGt(interestRate, 0);
    }

    function testRevertWhenBorrowWithLowHealthFactor() public {
        // Alice dépose des tokens
        vm.startPrank(alice);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et tente d'emprunter trop
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 100e18);
        pool.supplyCollateral(100e18);

        // Cette opération devrait échouer car le health factor serait trop bas
        vm.expectRevert("Health factor too low");
        pool.borrow(500e18);
        vm.stopPrank();
    }

    function testWithdrawCollateral() public {
        // Bob fournit du collatéral
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        
        // Retirer une partie du collatéral
        pool.withdrawCollateral(200e18);
        assertEq(pool.collateralSupplied(bob), 300e18);
        vm.stopPrank();
    }

    function testRevertWithdrawCollateralInsufficient() public {
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        
        vm.expectRevert("Insufficient collateral");
        pool.withdrawCollateral(600e18);
        vm.stopPrank();
    }

    function testRevertWithdrawCollateralBreachRatio() public {
        // Alice dépose des tokens
        vm.startPrank(alice);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        vm.stopPrank();

        // Bob fournit du collatéral et emprunte
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        pool.borrow(200e18);
        
        // Tenter de retirer trop de collatéral
        vm.expectRevert("Would breach collateral ratio");
        pool.withdrawCollateral(400e18);
        vm.stopPrank();
    }

    function testRepay() public {
        // Alice dépose des tokens
        vm.startPrank(alice);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        vm.stopPrank();

        // Bob emprunte
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        pool.borrow(200e18);
        
        // Rembourser une partie
        token.approve(address(pool), 300e18); // Approbation plus grande pour couvrir les intérêts
        pool.repay(100e18);
        assertEq(pool.userBorrows(bob), 100e18);
        vm.stopPrank();
    }

    function testRevertRepayExceedsBorrowings() public {
        // Alice dépose des tokens
        vm.startPrank(alice);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        vm.stopPrank();

        // Bob emprunte
        vm.startPrank(bob);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        cToken.approve(address(pool), 500e18);
        pool.supplyCollateral(500e18);
        pool.borrow(200e18);
        
        // Tenter de rembourser plus que l'emprunt
        token.approve(address(pool), 300e18);
        vm.expectRevert("Amount exceeds borrowings");
        pool.repay(300e18);
        vm.stopPrank();
    }

    function testUpdateCollateralRatio() public {
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        pool.updateCollateralRatio(16000); // 160%
        assertEq(pool.collateralRatio(), 16000);
        vm.stopPrank();
    }

    function testRevertUpdateCollateralRatioTooLow() public {
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        vm.expectRevert("Ratio must be at least 100%");
        pool.updateCollateralRatio(9999);
        vm.stopPrank();
    }

    function testUpdateInterestRateModel() public {
        InterestRateModel newModel = new InterestRateModel(500, 1000, 5000, 8000, 200, 15000);
        
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        pool.updateInterestRateModel(address(newModel));
        assertEq(address(pool.interestRateModel()), address(newModel));
        vm.stopPrank();
    }

    function testRevertUpdateInterestRateModelInvalidAddress() public {
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        vm.expectRevert("Invalid address");
        pool.updateInterestRateModel(address(0));
        vm.stopPrank();
    }

    function testUpdateProtocolFeeRate() public {
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        pool.updateProtocolFeeRate(100); // 1%
        assertEq(pool.protocolFeeRate(), 100);
        vm.stopPrank();
    }

    function testRevertUpdateProtocolFeeRateTooHigh() public {
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        vm.expectRevert("Fee rate too high");
        pool.updateProtocolFeeRate(1001); // > 10%
        vm.stopPrank();
    }

    // Helper function pour configurer une position liquide
    function _setupLiquidatablePosition(
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool useETH
    ) internal returns (LendingPool _pool, CToken _cToken) {
        // Calculer les frais de protocole une seule fois
        uint256 protocolFee = (borrowAmount * 50) / 10000; // 0.5% de frais
        uint256 totalNeeded = borrowAmount + protocolFee;

        // Créer la pool (ETH ou ERC20)
        if (useETH) {
            priceOracle.setPriceFeed(address(0), address(mockPriceFeed));
            _pool = LendingPool(payable(factory.createPool(
                address(0),
                "Ethereum",
                "ETH",
                15000,
                address(mockPriceFeed)
            )));
        } else {
            _pool = pool;
        }
        
        _cToken = CToken(_pool.cToken());
        
        // Déposer des fonds dans la pool pour permettre les emprunts
        if (useETH) {
            // Déposer plus d'ETH que nécessaire pour couvrir l'emprunt et les frais
            vm.deal(address(this), totalNeeded * 2); // Déposer le double pour être sûr
            _pool.deposit{value: totalNeeded * 2}(totalNeeded * 2);
        } else {
            token.mint(address(this), collateralAmount);
            token.approve(address(_pool), collateralAmount);
            _pool.deposit(collateralAmount);
        }
        
        // User dépose et fournit du collatéral
        vm.startPrank(user);
        if (useETH) {
            vm.deal(user, collateralAmount + totalNeeded);
            _pool.deposit{value: collateralAmount}(collateralAmount);
        } else {
            token.mint(user, collateralAmount);
            token.approve(address(_pool), collateralAmount);
            _pool.deposit(collateralAmount);
        }
        
        _cToken.approve(address(_pool), collateralAmount);
        _pool.supplyCollateral(collateralAmount);
        
        // Emprunter avec ETH
        if (useETH) {
            _pool.borrow{value: totalNeeded}(borrowAmount);
        } else {
            _pool.borrow(borrowAmount);
        }
        vm.stopPrank();
        
        // Créer un price feed séparé pour le CToken
        MockPriceFeed cTokenPriceFeed = new MockPriceFeed();
        priceOracle.setPriceFeed(address(_cToken), address(cTokenPriceFeed));
        
        // Simuler une baisse de prix
        cTokenPriceFeed.setPrice(0.2e18); // 80% de baisse pour le CToken
        mockPriceFeed.setPrice(1e18); // Prix normal pour le token/ETH
        
        return (_pool, _cToken);
    }

    function testLiquidation() public {
        // Setup initial
        uint256 initialCollateral = 1000e18;
        uint256 borrowAmount = 500e18;
        uint256 repayAmount = 250e18;
        
        // Configurer une position liquide (ERC20)
        (LendingPool testPool, CToken testCToken) = _setupLiquidatablePosition(
            bob,
            initialCollateral,
            borrowAmount,
            false
        );
        
        // Vérifier que le health factor est en dessous du seuil
        uint256 healthFactor = testPool.calculateHealthFactor(bob);
        assertLt(healthFactor, testPool.LIQUIDATION_THRESHOLD());

        // Alice dépose des tokens pour obtenir des CTokens
        vm.startPrank(alice);
        token.mint(alice, initialCollateral);
        token.approve(address(testPool), initialCollateral);
        testPool.deposit(initialCollateral);
        
        // Alice liquide la position
        token.approve(address(testPool), repayAmount);
        
        // Calculer le montant de collatéral attendu
        uint256 expectedCollateral = (repayAmount * testPool.collateralRatio()) / 10000;
        uint256 expectedBonus = (expectedCollateral * testPool.LIQUIDATION_BONUS()) / 10000;
        uint256 expectedTotalCollateral = expectedCollateral + expectedBonus;
        
        // Vérifier les balances avant liquidation
        uint256 aliceCollateralBefore = testPool.collateralSupplied(alice);
        uint256 bobCollateralBefore = testPool.collateralSupplied(bob);
        uint256 bobBorrowsBefore = testPool.userBorrows(bob);
        
        // Exécuter la liquidation
        testPool.liquidate(bob, repayAmount);
        
        // Vérifier les changements
        assertEq(testPool.collateralSupplied(alice), aliceCollateralBefore + expectedTotalCollateral);
        assertEq(testPool.collateralSupplied(bob), bobCollateralBefore - expectedTotalCollateral);
        assertEq(testPool.userBorrows(bob), bobBorrowsBefore - repayAmount);
        vm.stopPrank();
    }

    function testLiquidationWithETH() public {
        // Setup: Alice emprunte 500 ETH avec 1000 ETH de collatéral
        (LendingPool testPool, CToken testCToken) = _setupLiquidatablePosition(
            address(0x1), // Alice
            1000 ether,   // 1000 ETH de collatéral
            500 ether,    // 500 ETH d'emprunt
            true         // Utiliser ETH
        );

        // Vérifier que la position est liquidable
        uint256 healthFactor = testPool.calculateHealthFactor(address(0x1));
        assertTrue(healthFactor < testPool.LIQUIDATION_THRESHOLD(), "Position should be liquidable");

        // Bob va liquider la position d'Alice
        vm.startPrank(address(0x2)); // Bob

        // Calculer le montant à rembourser (50% de l'emprunt)
        uint256 repayAmount = 250 ether;

        // Donner à Bob assez d'ETH pour rembourser
        vm.deal(address(0x2), repayAmount);

        // Liquider la position
        testPool.liquidate{value: repayAmount}(address(0x1), repayAmount);

        // Vérifier les soldes après liquidation
        uint256 bobCollateral = testPool.collateralSupplied(address(0x2));
        uint256 aliceCollateral = testPool.collateralSupplied(address(0x1));

        // Bob devrait recevoir le collatéral d'Alice (moins le bonus de liquidation)
        uint256 expectedCollateral = (repayAmount * testPool.collateralRatio()) / 10000; // 150% = 15000/10000
        uint256 expectedBonus = (expectedCollateral * testPool.LIQUIDATION_BONUS()) / 10000; // 5% = 500/10000
        uint256 expectedTotalCollateral = expectedCollateral + expectedBonus;

        assertEq(bobCollateral, expectedTotalCollateral, "Bob should receive correct collateral amount");
        assertEq(aliceCollateral, 1000 ether - expectedTotalCollateral, "Alice should have remaining collateral");

        vm.stopPrank();
    }

    function testRevertWhenLiquidatingHealthyPosition() public {
        // Setup initial
        uint256 initialCollateral = 1000e18;
        uint256 borrowAmount = 100e18; // Montant plus petit pour garder un health factor élevé
        
        // Configurer une position saine (ERC20)
        (LendingPool pool, CToken cToken) = _setupLiquidatablePosition(
            bob,
            initialCollateral,
            borrowAmount,
            false
        );
        
        // Vérifier que le health factor est au-dessus du seuil
        uint256 healthFactor = pool.calculateHealthFactor(bob);
        assertGt(healthFactor, pool.LIQUIDATION_THRESHOLD());
        
        // Alice essaie de liquider la position
        vm.startPrank(alice);
        token.mint(alice, initialCollateral);
        token.approve(address(pool), initialCollateral);
        pool.deposit(initialCollateral);
        
        // La liquidation devrait échouer
        vm.expectRevert("Health factor too high");
        pool.liquidate(bob, 50e18);
        vm.stopPrank();
    }

    function testRevertWhenLiquidatingWithInvalidAmount() public {
        // Setup initial
        uint256 initialCollateral = 1000e18;
        uint256 borrowAmount = 500e18;
        
        // Configurer une position liquide (ERC20)
        (LendingPool pool, CToken cToken) = _setupLiquidatablePosition(
            bob,
            initialCollateral,
            borrowAmount,
            false
        );
        
        // Alice essaie de liquider avec un montant invalide
        vm.startPrank(alice);
        token.mint(alice, initialCollateral);
        token.approve(address(pool), initialCollateral);
        pool.deposit(initialCollateral);
        
        // La liquidation devrait échouer
        vm.expectRevert("Amount must be > 0");
        pool.liquidate(bob, 0);
        vm.stopPrank();
    }

    function testRevertConstructorCollateralRatioTooLow() public {
        address asset = address(token);
        address cTokenAddr = address(cToken);
        address interestRateModel = address(new InterestRateModel(100, 200, 400, 8000, 50, 2000));
        address priceOracleAddr = address(priceOracle);
        uint256 invalidRatio = 9999;
        vm.expectRevert("Collateral ratio must be >= 100%");
        new LendingPool(asset, cTokenAddr, interestRateModel, priceOracleAddr, invalidRatio);
    }

    function testUpdateInterestRateDefaultWhenNoDeposits() public {
        // Déployer un nouveau pool sans dépôt
        address asset = address(token);
        address cTokenAddr = address(cToken);
        address interestRateModel = address(new InterestRateModel(100, 200, 400, 8000, 50, 2000));
        address priceOracleAddr = address(priceOracle);
        uint256 ratio = 15000;
        LendingPool newPool = new LendingPool(asset, cTokenAddr, interestRateModel, priceOracleAddr, ratio);
        // totalDeposits == 0
        newPool.updateInterestRate();
        assertEq(newPool.currentInterestRate(), 500); // Taux par défaut
    }

    function testUpdateInterestRateWithDeposits() public {
        // Mint des tokens à l'adresse du test
        token.mint(address(this), 1000e18);
        token.approve(address(pool), 1000e18);
        pool.deposit(1000e18);
        // Le taux doit être mis à jour via le modèle
        pool.updateInterestRate();
        uint256 rate = pool.currentInterestRate();
        assertGt(rate, 0);
    }

    function testRevertCollectProtocolFeesWhenNoFees() public {
        // Utiliser la factory comme propriétaire
        vm.startPrank(address(factory));
        vm.expectRevert("No fees to collect");
        pool.collectProtocolFees();
        vm.stopPrank();
    }

    function testCollectProtocolFeesETH() public {
        // Créer une pool ETH via la factory
        priceOracle.setPriceFeed(address(0), address(mockPriceFeed));
        address payable ethPoolAddr = payable(factory.createPool(
            address(0),
            "Ethereum",
            "ETH",
            15000,
            address(mockPriceFeed)
        ));
        LendingPool ethPool = LendingPool(ethPoolAddr);
        CToken ethCToken = CToken(ethPool.cToken());
        priceOracle.setPriceFeed(address(ethCToken), address(mockPriceFeed));

        // Déposer de l'ETH pour générer de la liquidité
        vm.deal(address(this), 10 ether);
        ethPool.deposit{value: 10 ether}(10 ether);

        // Bob dépose, fournit du collatéral et emprunte pour générer des frais
        vm.deal(bob, 10 ether);
        vm.startPrank(bob);
        ethPool.deposit{value: 5 ether}(5 ether);
        ethCToken.approve(address(ethPool), 2 ether);
        ethPool.supplyCollateral(2 ether);
        uint256 protocolFee = (1 ether * ethPool.protocolFeeRate()) / 10000;
        ethPool.borrow{value: 1 ether + protocolFee}(1 ether);
        vm.stopPrank();

        // Vérifier que des frais ont été générés
        uint256 expectedFees = (1 ether * ethPool.protocolFeeRate()) / 10000;
        assertEq(ethPool.protocolFees(), expectedFees, "ETH pool: Incorrect protocol fees");

        // Collecter les frais en tant que owner (factory)
        uint256 balanceBefore = address(factory).balance;
        vm.startPrank(address(factory));
        ethPool.collectProtocolFees();
        vm.stopPrank();
        uint256 balanceAfter = address(factory).balance;
        assertEq(ethPool.protocolFees(), 0, "ETH pool: Fees not collected");
        assertEq(balanceAfter, balanceBefore + expectedFees, "ETH pool: Fees not transferred to owner");
    }

    function testRevertCollectProtocolFeesETHTransferFail() public {
        // Déployer un contrat qui refuse l'ETH
        RejectETH rejector = new RejectETH();
        // Créer un CToken et une pool de test dédiés
        CToken newEthCToken = new CToken("Test ETH CToken", "T-ETHC", address(0));
        TestLendingPool ethPool = new TestLendingPool(
            address(0),
            address(newEthCToken),
            address(new InterestRateModel(100, 200, 400, 8000, 50, 2000)),
            address(priceOracle),
            15000
        );
        newEthCToken.setLendingPool(address(ethPool));
        
        // Transférer la propriété au contrat qui refuse l'ETH
        ethPool.transferOwnership(address(rejector));

        // Simuler des frais directement
        ethPool.addProtocolFees(1 ether);

        // Tenter de collecter les frais, doit revert
        vm.startPrank(address(rejector));
        vm.expectRevert("ETH transfer failed");
        ethPool.collectProtocolFees();
        vm.stopPrank();
    }
}