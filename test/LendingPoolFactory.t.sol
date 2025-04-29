// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/core/LendingPoolFactory.sol";
import "../src/core/LendingPool.sol";
import "../src/tokens/CToken.sol";

contract LendingPoolFactoryTest is Test {
    LendingPoolFactory public factory;
    address public deployer;
    address public user;

    // Adresses simulées pour les tests
    address constant ETH_ADDRESS = address(0);
    address constant MOCK_DAI = address(0x1);

    function setUp() public {
        deployer = address(this);
        user = makeAddr("user");

        // Déploiement de la factory
        factory = new LendingPoolFactory();

        vm.label(address(factory), "Factory");
        vm.label(MOCK_DAI, "DAI");
    }

    function testCreateEthPool() public {
        // Création d'une pool ETH
        factory.createPool(
            ETH_ADDRESS,
            "Ethereum",
            "ETH",
            15000  // 150% ratio
        );

        // Vérifier que la pool a été créée et est bien référencée
        address payable ethPoolAddress = payable(factory.assetToPools(ETH_ADDRESS));
        assertTrue(ethPoolAddress != address(0), "ETH pool not created");

        // Vérifier que la pool est dans le tableau des pools
        address[] memory allPools = factory.getAllPools();
        assertEq(allPools.length, 1, "Pool not added to array");
        assertEq(allPools[0], ethPoolAddress, "Incorrect pool address");

        // Vérifier que la pool est correctement configurée
        LendingPool ethPool = LendingPool(ethPoolAddress);
        assertEq(ethPool.asset(), ETH_ADDRESS, "Incorrect asset");
        assertEq(ethPool.collateralRatio(), 15000, "Incorrect ratio");
    }

    function testCreateErc20Pool() public {
        // Création d'une pool pour un token ERC20
        factory.createPool(
            MOCK_DAI,
            "DAI Stablecoin",
            "DAI",
            12500  // 125% ratio
        );

        // Vérifier que la pool a été créée et est bien référencée
        address payable daiPoolAddress = payable(factory.assetToPools(MOCK_DAI));
        assertTrue(daiPoolAddress != address(0), "DAI pool not created");

        // Vérifier les détails de la pool
        LendingPool daiPool = LendingPool(daiPoolAddress);
        assertEq(daiPool.asset(), MOCK_DAI, "Incorrect asset");
        assertEq(daiPool.collateralRatio(), 12500, "Incorrect ratio");

        // Vérifier le cToken
        address cTokenAddress = daiPool.cToken();
        CToken cToken = CToken(cTokenAddress);
        assertEq(cToken.asset(), MOCK_DAI, "Incorrect cToken asset");
        assertEq(cToken.lendingPool(), daiPoolAddress, "Incorrect cToken lending pool");
    }

    function testCannotCreateDuplicatePool() public {
        // Créer une première pool
        factory.createPool(MOCK_DAI, "DAI Stablecoin", "DAI", 12500);

        // Tenter de créer une deuxième pool pour le même actif doit échouer
        vm.expectRevert("Pool already exists for this asset");
        factory.createPool(MOCK_DAI, "DAI Pool 2", "DAI2", 12500);
    }

    function testGetPoolCount() public {
        assertEq(factory.getPoolCount(), 0, "Initial pool count should be 0");

        // Créer plusieurs pools
        factory.createPool(ETH_ADDRESS, "Ethereum", "ETH", 15000);
        factory.createPool(MOCK_DAI, "DAI Stablecoin", "DAI", 12500);

        assertEq(factory.getPoolCount(), 2, "Pool count should be 2");
    }

    function testGetAllPools() public {
        // Créer plusieurs pools
        factory.createPool(ETH_ADDRESS, "Ethereum", "ETH", 15000);
        factory.createPool(MOCK_DAI, "DAI Stablecoin", "DAI", 12500);

        address[] memory pools = factory.getAllPools();
        assertEq(pools.length, 2, "Should return 2 pools");

        // Vérifier que les adresses correspondent
        assertEq(pools[0], factory.assetToPools(ETH_ADDRESS), "First pool should be ETH pool");
        assertEq(pools[1], factory.assetToPools(MOCK_DAI), "Second pool should be DAI pool");
    }

    function testOnlyOwnerCanCreatePool() public {
        // Essayer de créer une pool à partir d'un compte non-propriétaire
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.createPool(ETH_ADDRESS, "Ethereum", "ETH", 15000);
    }
}