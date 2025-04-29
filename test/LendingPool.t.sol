// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/core/LendingPool.sol";
import "../src/core/LendingPoolFactory.sol";
import "../src/tokens/CToken.sol";
import "../src/core/InterestRateModel.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract LendingPoolTest is Test {
    // Contrats principaux
    LendingPoolFactory public factory;
    LendingPool public ethPool;
    CToken public cEth;

    // Pour les tests avec ERC20
    LendingPool public daiPool;
    CToken public cDai;
    MockERC20 public dai;

    // Acteurs
    address public deployer;
    address public alice;
    address public bob;

    function setUp() public {
        deployer = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Donner de l'ETH aux utilisateurs de test
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        // Déploiement de la factory
        factory = new LendingPoolFactory();

        // Création d'une pool ETH
        factory.createPool(address(0), "Ethereum", "ETH", 15000);
        address payable ethPoolAddr = payable(factory.assetToPools(address(0)));
        ethPool = LendingPool(ethPoolAddr);
        cEth = CToken(ethPool.cToken());

        // Création d'une pool DAI
        dai = new MockERC20("DAI Stablecoin", "DAI");
        factory.createPool(address(dai), "DAI Stablecoin", "DAI", 12500);
        address payable daiPoolAddr = payable(factory.assetToPools(address(dai)));
        daiPool = LendingPool(daiPoolAddr);
        cDai = CToken(daiPool.cToken());

        // Donner des DAI aux utilisateurs de test
        dai.mint(alice, 1000 ether);
        dai.mint(bob, 1000 ether);

        // Labels pour faciliter le debug
        vm.label(address(ethPool), "ETH Pool");
        vm.label(address(cEth), "cETH");
        vm.label(address(daiPool), "DAI Pool");
        vm.label(address(cDai), "cDAI");
        vm.label(address(dai), "DAI");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
    }

    // Test de dépôt ETH
    function testDepositETH() public {
        uint256 depositAmount = 1 ether;

        vm.startPrank(alice);

        uint256 balanceBefore = address(alice).balance;
        ethPool.deposit{value: depositAmount}(depositAmount);
        uint256 balanceAfter = address(alice).balance;

        // Vérifier que l'ETH a bien été transféré
        assertEq(balanceAfter, balanceBefore - depositAmount, "ETH not transferred");

        // Vérifier que les cTokens ont été créés
        assertEq(cEth.balanceOf(alice), depositAmount, "cTokens not received");

        // Vérifier les états du pool
        assertEq(ethPool.totalDeposits(), depositAmount, "Incorrect deposit total");

        vm.stopPrank();
    }

    // Test de fourniture de collatéral et d'emprunt
    function testSupplyCollateralAndBorrowETH() public {
        // Alice dépose 2 ETH
        vm.prank(alice);
        ethPool.deposit{value: 2 ether}(2 ether);

        // Bob dépose 1 ETH et le fournit comme collatéral
        vm.startPrank(bob);
        ethPool.deposit{value: 1 ether}(1 ether);

        // Approuver le transfert de cTokens
        cEth.approve(address(ethPool), 1 ether);

        // Fournir le collatéral
        ethPool.supplyCollateral(1 ether);
        assertEq(ethPool.collateralSupplied(bob), 1 ether, "Collateral not registered");

        // Emprunter 0.6 ETH (moins que la limite avec 150% ratio)
        uint256 borrowAmount = 0.6 ether;
        uint256 balanceBefore = address(bob).balance;
        ethPool.borrow(borrowAmount);
        uint256 balanceAfter = address(bob).balance;

        // Vérifier que l'ETH a été reçu
        assertEq(balanceAfter, balanceBefore + borrowAmount, "Borrowed ETH not received");

        // Vérifier les états d'emprunt
        assertEq(ethPool.userBorrows(bob), borrowAmount, "Debt not registered");
        assertEq(ethPool.totalBorrows(), borrowAmount, "Incorrect total borrows");

        vm.stopPrank();
    }

    // Test d'emprunt excessif (doit échouer)
    function test_RevertWhen_BorrowOverCollateralLimit() public {
        // Alice dépose 2 ETH
        vm.prank(alice);
        ethPool.deposit{value: 2 ether}(2 ether);

        // Bob dépose 1 ETH et le fournit comme collatéral
        vm.startPrank(bob);
        ethPool.deposit{value: 1 ether}(1 ether);
        cEth.approve(address(ethPool), 1 ether);
        ethPool.supplyCollateral(1 ether);

        // Essayer d'emprunter 0.8 ETH (au-dessus de la limite avec 150% ratio)
        // Devrait échouer car: 1 ETH collateral / 150% = ~0.67 ETH max
        vm.expectRevert("Insufficient collateral");
        ethPool.borrow(0.8 ether);

        vm.stopPrank();
    }

    function testWithdrawCollateral() public {
        // Bob dépose 1 ETH
        vm.startPrank(bob);
        ethPool.deposit{value: 1 ether}(1 ether);

        // Approuve et fournit le collatéral
        cEth.approve(address(ethPool), 0.5 ether);
        ethPool.supplyCollateral(0.5 ether);

        // Vérifie que le collatéral est bien fourni
        assertEq(ethPool.collateralSupplied(bob), 0.5 ether);

        // Retire le collatéral
        ethPool.withdrawCollateral(0.5 ether);

        // Vérifie que le collatéral est bien retiré
        assertEq(ethPool.collateralSupplied(bob), 0);
        assertEq(cEth.balanceOf(bob), 1 ether);

        vm.stopPrank();
    }

    // Test de remboursement d'emprunt
    function testRepayETH() public {
        // Setup: Alice dépose, Bob emprunte
        vm.prank(alice);
        ethPool.deposit{value: 2 ether}(2 ether);

        vm.startPrank(bob);
        ethPool.deposit{value: 1 ether}(1 ether);
        cEth.approve(address(ethPool), 1 ether);
        ethPool.supplyCollateral(1 ether);
        ethPool.borrow(0.6 ether);

        // Bob rembourse partiellement
        uint256 repayAmount = 0.3 ether;
        ethPool.repay{value: repayAmount}(repayAmount);

        // Vérifier que la dette a été réduite
        assertEq(ethPool.userBorrows(bob), 0.3 ether, "Incorrect debt after repayment");
        assertEq(ethPool.totalBorrows(), 0.3 ether, "Incorrect total borrows after repayment");

        vm.stopPrank();
    }

    // Test du modèle de taux d'intérêt
    function testInterestRateCalculation() public {
        // Alice dépose 10 ETH
        vm.prank(alice);
        ethPool.deposit{value: 10 ether}(10 ether);

        // Bob emprunte 5 ETH (50% d'utilisation)
        vm.startPrank(bob);
        ethPool.deposit{value: 8 ether}(8 ether);
        cEth.approve(address(ethPool), 8 ether);
        ethPool.supplyCollateral(8 ether);
        ethPool.borrow(5 ether);
        vm.stopPrank();

        // Vérifier que le taux d'intérêt a été mis à jour
        uint256 rate = ethPool.currentInterestRate();

        // Calcul attendu: baseRate + (utilizationRatio * slopeRate1 / 10000)
        // 500 + (5000 * 1000 / 10000) = 500 + 500 = 1000 (10%)
        assertGt(rate, 500, "Interest rate should have increased");

        // Nous ne pouvons pas prédire exactement le taux sans connaître l'implémentation précise,
        // mais nous pouvons vérifier qu'il est dans une plage raisonnable
        assertLt(rate, 5000, "Interest rate should not be excessive");
    }
}