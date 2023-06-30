// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, STARTING_ERC20_BALANCE);
    }

    /* ===== Constructor Tests ===== */
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertIfTokenLenghtDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /* ===== Price Tests ===== */

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/ETH = 30,000e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(actualUsd, expectedUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    /* ===== depositCollateral Tests ===== */

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();
        ranToken.mint(USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(expectedTotalDscMinted, totalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    /* ===== mintDsc Tests ===== */

    function testMintDsc() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.prank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        assertEq(collateralValueInUsd / 2, dsc.balanceOf(USER) - totalDscMinted);
    }

    function testRevertIfMintWithoutEnoughCollateral() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        vm.expectRevert();
        dscEngine.mintDsc(collateralValueInUsd);
        vm.stopPrank();
    }

    function testDepositCollateralAndMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        uint256 expectedDscMinted = dscEngine.getUsdValue(weth, AMOUNT_COLLATERAL) / 2;
        dscEngine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, expectedDscMinted);
        assertEq(expectedDscMinted, dsc.balanceOf(USER));
        vm.stopPrank();
    }

    /* ===== redeemCollateral Tests ===== */

    function testRedeemCollateralForDsc() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        (uint256 totalDscMinted,) = dscEngine.getAccountInformation(USER);
        dsc.approve(address(dscEngine), totalDscMinted);
        uint256 wethBalanceBefore = ERC20Mock(weth).balanceOf(USER);
        dscEngine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, totalDscMinted);
        assertEq(dscEngine.getCollateralBalanceOfUser(weth, USER), 0);
        assertEq(0, dsc.balanceOf(USER));
        assertEq(AMOUNT_COLLATERAL + wethBalanceBefore, ERC20Mock(weth).balanceOf(USER));
        vm.stopPrank();
    }

    function testRedeemCollateral() public depositedCollateral {
        vm.startPrank(USER);
        uint256 wethBalanceBefore = ERC20Mock(weth).balanceOf(USER);
        dscEngine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        assertEq(0, dscEngine.getCollateralBalanceOfUser(weth, USER));
        assertEq(AMOUNT_COLLATERAL + wethBalanceBefore, ERC20Mock(weth).balanceOf(USER));
        vm.stopPrank();
    }

    /* ===== burnDsc Tests ===== */

    function testBurnDsc() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        uint256 dscBalanceBefore = dsc.balanceOf(USER);
        dsc.approve(address(dscEngine), dscBalanceBefore);
        dscEngine.burnDsc(dscBalanceBefore);
        assertEq(0, dsc.balanceOf(USER));
        vm.stopPrank();
    }

    /* ===== liquidate Tests ===== */

    function testLiquidate() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        dsc.transfer(LIQUIDATOR, dsc.balanceOf(USER));
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(1900e8); // update price to 1000 (/2)
        uint256 liquidatorBalance = dsc.balanceOf(LIQUIDATOR);
        dsc.approve(address(dscEngine), liquidatorBalance);
        dscEngine.liquidate(weth, USER, liquidatorBalance);
        vm.stopPrank();
    }

    function testPartialLiquidate() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        dsc.transfer(LIQUIDATOR, dsc.balanceOf(USER));
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(1900e8); // update price to 1000 (/2)
        uint256 liquidatorBalance = dsc.balanceOf(LIQUIDATOR);
        dsc.approve(address(dscEngine), liquidatorBalance / 2);
        dscEngine.liquidate(weth, USER, liquidatorBalance / 2);
        vm.stopPrank();
    }

    function testRevertIfHealthFactorIsNotBroken() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        dsc.transfer(LIQUIDATOR, dsc.balanceOf(USER));
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(2000e8); // update price to 1000 (/2)
        uint256 liquidatorBalance = dsc.balanceOf(LIQUIDATOR);
        dsc.approve(address(dscEngine), liquidatorBalance);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactoOk.selector, 1000000000000000000));
        dscEngine.liquidate(weth, USER, liquidatorBalance);
        vm.stopPrank();
    }

    /* ===== public & external view Tests ===== */

    function testGetCollateralBalanceOfUser() public depositedCollateral {
        assertEq(AMOUNT_COLLATERAL, dscEngine.getCollateralBalanceOfUser(USER, weth));
    }

    function testGetAccountCollateralValue() public depositedCollateral {
        vm.startPrank(USER);
        ERC20Mock(wbtc).mint(USER, AMOUNT_COLLATERAL);
        ERC20Mock(wbtc).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(wbtc, AMOUNT_COLLATERAL);
        uint256 totalValueInUsdExpected = dscEngine.getUsdValue(weth, AMOUNT_COLLATERAL) + dscEngine.getUsdValue(wbtc, AMOUNT_COLLATERAL);
        uint256 totalValueInUsd = dscEngine.getAccountCollateralValue(USER);
        assertEq(totalValueInUsd, totalValueInUsdExpected);
        vm.stopPrank();
    }

    function testCalculateHealtFactor() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        uint256 dscBalanceBefore = dsc.balanceOf(USER);
        uint256 healthFactor = dscEngine.calculateHealthFactor(dscBalanceBefore, collateralValueInUsd);
        uint256 expectedHealthFactor = dscEngine.getMinHealthFactor();
        assertEq(expectedHealthFactor, healthFactor);
        vm.stopPrank();
    }

    function testGetHealthFactor() public depositedCollateral {
        (, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        vm.startPrank(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        uint256 healthFactor = dscEngine.getHealthFactor(USER);
        uint256 expectedHealthFactor = dscEngine.getMinHealthFactor();
        assertEq(expectedHealthFactor, healthFactor);
        vm.stopPrank();
    }

    function testGetAccountInformation() public depositedCollateral {
        vm.startPrank(USER);
        (,uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        dscEngine.mintDsc(collateralValueInUsd / 2);
        (uint256 totalDscMintedAfter, uint256 collateralValueInUsdAfter) = dscEngine.getAccountInformation(USER);
        assertEq(collateralValueInUsd / 2, totalDscMintedAfter);
        assertEq(collateralValueInUsd, collateralValueInUsdAfter);
    }

    /* ===== const getters Tests ===== */

    function testGetPrecision() public {
        assertEq(1e18, dscEngine.getPrecision());
    }

    function testGetAdditionalFeedPrecision() public {
        assertEq(1e10, dscEngine.getAdditionalFeedPrecision());
    }

    function testGetLiquidationThreshold() public {
        assertEq(50, dscEngine.getLiquidationThreshold());
    }

    function testGetLiquidationBonus() public {
        assertEq(10, dscEngine.getLiquidationBonus());
    }

    function testGetMinHealthFactor() public {
        assertEq(1e18, dscEngine.getMinHealthFactor());
    }

    /* ===== immutable getters Tests ===== */

    function testGetCollateralTokens() public {
        assertEq(weth, dscEngine.getCollateralTokens()[0]);
        assertEq(wbtc, dscEngine.getCollateralTokens()[1]);
    }

    function testGetDsc() public {
        assertEq(address(dsc), dscEngine.getDsc());
    }

    function testGetCollateralTokenPriceFeed() public {
        assertEq(ethUsdPriceFeed, dscEngine.getCollateralTokenPriceFeed(weth));
        assertEq(btcUsdPriceFeed, dscEngine.getCollateralTokenPriceFeed(wbtc));
    }

}
