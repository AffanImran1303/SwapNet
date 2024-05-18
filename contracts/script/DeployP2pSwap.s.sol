// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {P2pSwap} from "../src/P2PSwap.sol";

contract DeployP2pSwap is Script {
    function run(address _router) public returns (P2pSwap) {
        HelperConfig helperConfig = new HelperConfig();
        (address feedRegistry) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        console.log("started deploying...");

        P2pSwap p2pSwap = new P2pSwap(_router, feedRegistry);
        console.log("Finished deploying");
        vm.stopBroadcast();
        return (p2pSwap);
    }
}
