// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
        //targetContract(address(dscEngine));
        handler = new Handler(dscEngine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        // compare the value of the protocol to the total supply of DSC
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscEngine.getUsdValue(wbtc, totalWbtcDeposited);
        console.log("wethValue: %s", wethValue);
        console.log("wbtcValue: %s", wbtcValue);
        console.log("totalSupply: %s", totalSupply);
        console.log("totalWethDeposited: %s", totalWethDeposited);
        uint256 protocolValue = wethValue + wbtcValue;

        assert(protocolValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        

        dscEngine.getPrecision(); 

        dscEngine.getAdditionalFeedPrecision();

        dscEngine.getLiquidationThreshold(); 

        dscEngine.getLiquidationBonus(); 

        dscEngine.getMinHealthFactor();

        dscEngine.getCollateralTokens(); 

        dscEngine.getDsc();

        // dscEngine.getCollateralTokenPriceFeed(address token); 

        // dscEngine.getHealthFactor(address user); 
        // dscEngine.getTokenAmountFromUsd(address token, uint256 usdAmountInWei);

        // dscEngine.getCollateralBalanceOfUser(address user, address token);

        // dscEngine.getAccountCollateralValue(address user);

        // dscEngine.getUsdValue(address token, uint256 amount); 

        // dscEngine.getAccountInformation(address user);

        // dscEngine.calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd);
    }
}
