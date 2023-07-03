// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin dsc;
    address public USER = makeAddr("user");

    function setUp() public {
        vm.prank(USER);
        dsc = new DecentralizedStableCoin();
    }

    function testMint() public {
        vm.startPrank(USER);
        dsc.mint(USER, 100);
        assertEq(dsc.balanceOf(USER), 100);
        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(USER);
        dsc.mint(address(this), 100);
        dsc.burn(50);
        assertEq(dsc.balanceOf(USER), 50);
        vm.stopPrank();
    }

    function testRevertIfMintAmountIsZero() public {
        vm.startPrank(USER);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.mint(USER, 0);
        vm.stopPrank();
    }

    function testRevertIfMintToZeroAddress() public {
        vm.startPrank(USER);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector);
        dsc.mint(address(0), 100);
        vm.stopPrank();
    }

    function testRevertIfBurnAmountIsZero() public {
        vm.startPrank(USER);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.burn(0);
        vm.stopPrank();
    }

    function testRevertIfBurnMoreThanBalance() public {
        vm.startPrank(USER);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(100);
        vm.stopPrank();
    }
}
