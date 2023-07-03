// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {OracleLib} from "../../src/libraries/OracleLib.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract OracleLibTest is Test {
    AggregatorV3Interface priceFeed;
    MockV3Aggregator aggregator;
    int256 public constant INITIAL_PRICE = 2000;
    uint8 public constant PRECISION = 8;

    using OracleLib for AggregatorV3Interface;

    function setUp() public {
        aggregator = new MockV3Aggregator(PRECISION, INITIAL_PRICE);
    }

    function testGetTimeout() public {
        uint256 expectedTimeout = 3 hours;
        uint256 timeout = OracleLib.getTimeout(AggregatorV3Interface(aggregator));
        assertEq(timeout, expectedTimeout);
    }

    function testPriceRevertsOnStaleCheck() public {
        vm.warp(block.timestamp + 4 hours);
        vm.roll(block.number + 1);

        vm.expectRevert(OracleLib.OracleLib__StalePrice.selector);
        AggregatorV3Interface(aggregator).staleCheckLatestRoundData();
    }

    function testPriceRevertsOnBadAnswerdInRound() public {
        uint80 _roundId = 0;
        int256 _answer = 0;
        uint256 _timestamp = 0;
        uint256 _startedAt = 0;
        aggregator.updateRoundData(_roundId, _answer, _timestamp, _startedAt);

        vm.expectRevert(OracleLib.OracleLib__StalePrice.selector);
        AggregatorV3Interface(address(aggregator)).staleCheckLatestRoundData();
    }
}
