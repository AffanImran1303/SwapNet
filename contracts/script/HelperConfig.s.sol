// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {Denominations} from "@chainlink/brownie/Denominations.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address feedRegistry;
    }

    int256 constant PRICE_FOR_CCIPBNM_IN_USD = 10e18;
    int256 constant PRICE_FOR_CCIPLNM_IN_USD = 5e18;

    address constant CCIPBNM_TOKEN_ADDRESS = 0xDDc10602782af652bB913f7bdE1fD82981Db7dd9;
    address constant CCIPLNM_TOKEN_ADDRESS = 0x7FdB3132Ff7D02d8B9e221c61cC895ce9a4bb773;

    uint8 constant DECIMALS = 18;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        activeNetworkConfig = createAnvilNetworkConfiguration();
    }

    function createAnvilNetworkConfiguration() public returns (NetworkConfig memory) {
        MockV3Aggregator feedRegistry = new MockV3Aggregator(DECIMALS, PRICE_FOR_CCIPBNM_IN_USD);
        feedRegistry.updateAnswerForTokenPair(CCIPBNM_TOKEN_ADDRESS, Denominations.USD, PRICE_FOR_CCIPBNM_IN_USD, DECIMALS);
        feedRegistry.updateAnswerForTokenPair(CCIPLNM_TOKEN_ADDRESS, Denominations.USD, PRICE_FOR_CCIPLNM_IN_USD, DECIMALS);

        return NetworkConfig({feedRegistry: address(feedRegistry)});
    }
}
