// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address feedRegistry;
    }

    int256 constant PRICE_FOR_ASSET = 2e18;
    uint8 constant DECIMALS = 18;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        activeNetworkConfig = createAnvilNetworkConfiguration();
    }

    function createAnvilNetworkConfiguration() public returns (NetworkConfig memory) {
        MockV3Aggregator feedRegistry = new MockV3Aggregator(DECIMALS, PRICE_FOR_ASSET);
        return NetworkConfig({feedRegistry: address(feedRegistry)});
    }
}
