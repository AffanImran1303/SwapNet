// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {NormalSwap} from "../src/NormalSwap.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";


contract NormalSwapTest is Test {
    CCIPLocalSimulatorFork ccipLocalSimulatorFork;

    uint256 ethMainNetForkID;
    uint256 arbMainNetForkID;

    Register.NetworkDetails ethNetworkDetails;
    Register.NetworkDetails arbNetworkDetails;

    NormalSwap ethSwapContract;
    NormalSwap arbSwapContract;

    // address constant ETH_UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // address constant ETH_UNISWAP_ROUTER = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address constant ETH_UNISWAP_ROUTER = 0xb41b78Ce3D1BDEDE48A3d303eD2564F6d1F6fff0;
    address constant ARB_UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address USER_ETH_ADDRESS = makeAddr("user-eth-address");
    address USER_ARB_ADDRESS = makeAddr("user-arb-address");

    address constant ASSET_FROM = 0x68194a729C2450ad26072b3D33ADaCbcef39D574; // DAI CONTRACT ADDRESS 0x68194a729C2450ad26072b3D33ADaCbcef39D574
    address constant ASSET_TO = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d; // USDC CONTRACT ADDRESS

    function setUp() public {
        string memory ETH_TEST_NET_URL = vm.envString("ETH_TEST_NET_URL");
        string memory ARB_TEST_NET_URL = vm.envString("ARB_TEST_NET_URL");

        arbMainNetForkID = vm.createFork(ARB_TEST_NET_URL);
        ethMainNetForkID = vm.createSelectFork(ETH_TEST_NET_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
        vm.makePersistent(ETH_UNISWAP_ROUTER);

        ethNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        ethSwapContract = new NormalSwap(ethNetworkDetails.routerAddress, ETH_UNISWAP_ROUTER);
        deal(ASSET_FROM, USER_ETH_ADDRESS, 10 ether);

        vm.selectFork(arbMainNetForkID);
        arbNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        arbSwapContract = new NormalSwap(arbNetworkDetails.routerAddress, ARB_UNISWAP_ROUTER);
    }

    function testSwapAsset() public {
        vm.selectFork(ethMainNetForkID);
        vm.startPrank(USER_ETH_ADDRESS);
        uint256 amountToSwap = 5 ether;

        IERC20(ASSET_FROM).approve(address(ethSwapContract), amountToSwap);
        vm.deal(address(ethSwapContract), 5 ether);

        ethSwapContract.swapAsset(
            ASSET_FROM,
            ASSET_TO,
            amountToSwap,
            arbNetworkDetails.chainSelector,
            address(arbSwapContract),
            USER_ARB_ADDRESS
        );
    }

}
