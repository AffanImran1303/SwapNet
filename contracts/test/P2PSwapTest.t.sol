// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {IRouterClient, WETH9, LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {CCIPLocalSimulator} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {P2pSwap} from "../src/P2PSwap.sol";
import {DeployP2pSwap} from "../script/DeployP2pSwap.s.sol";

contract P2PSwapTest is Test {
    CCIPLocalSimulator public ccipSimulator;
    P2pSwap public sellerContract;
    P2pSwap public buyerContract;
    DeployP2pSwap deployer;

    BurnMintERC677Helper sellerAsset;
    BurnMintERC677Helper buyerAsset;
    uint64 destinationChainSelector;

    // SOURCE ADDRESSES
    address SELLER_1 = makeAddr("Seller_1");
    address BUYER_1 = makeAddr("Buyer_1");
    address BUYER_2 = makeAddr("Buyer_2");

    // DESTINATION ADDRESS
    address SELLER_1_DESTINATION_ADDRESS = makeAddr("Seller_1_destination_address");
    address BUYER_1_DESTINATION_ADDRESS = makeAddr("Buyer_1_destination_address");
    address BUYER_2_DESTINATION_ADDRESS = makeAddr("Buyer_2_destination_address");

    uint256 constant CONTRACT_BALANCE = 10 ether;
    uint256 constant AMOUNT_OF_ASSET_TO_SELL = 500;

    function setUp() public {
        ccipSimulator = new CCIPLocalSimulator();
        deployer = new DeployP2pSwap();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            WETH9 wrappedNative,
            ,
            BurnMintERC677Helper ccipBnM,
            BurnMintERC677Helper ccipLnM
        ) = ccipSimulator.configuration();

        destinationChainSelector = chainSelector;

        sellerContract = deployer.run(address(sourceRouter));
        buyerContract = deployer.run(address(destinationRouter));

        hoax(address(sellerContract), CONTRACT_BALANCE);
        wrappedNative.deposit{value: 5 ether}();
        hoax(address(buyerContract), CONTRACT_BALANCE);
        wrappedNative.deposit{value: 5 ether}();

        sellerAsset = ccipBnM;
        buyerAsset = ccipLnM;

        console.log("ccipBnM token address: ", address(ccipBnM));
        console.log("ccipLnM token address: ", address(ccipLnM));
    }

    modifier giveSellerSomeAssetToSell(address seller) {
        sellerAsset.drip(seller);
        _;
    }

    function createSwapPostion() internal returns (bytes32) {
        uint8 sellerExchangeRate = 5;
        vm.startPrank(SELLER_1);
        sellerAsset.approve(address(sellerContract), AMOUNT_OF_ASSET_TO_SELL);
        bytes32 positionHash = sellerContract.createSwapPosition(
            address(sellerAsset),
            address(buyerAsset),
            address(buyerContract),
            SELLER_1_DESTINATION_ADDRESS,
            AMOUNT_OF_ASSET_TO_SELL,
            sellerExchangeRate,
            destinationChainSelector
        );
        vm.stopPrank();
        return positionHash;
    }

    function testCreateSwapPosition() public giveSellerSomeAssetToSell(SELLER_1) {
        uint256 totalNumberOfPositionsInBuyerContractBeforeSwap = buyerContract.getTotalNumberOfOpenPositions();
        uint8 sellerExchangeRate = 5;
        console.log(
            "Number of position in buyer contract before swap position creation:",
            totalNumberOfPositionsInBuyerContractBeforeSwap
        );

        vm.startPrank(SELLER_1);
        sellerAsset.approve(address(sellerContract), AMOUNT_OF_ASSET_TO_SELL);
        bytes32 positionHash = sellerContract.createSwapPosition(
            address(sellerAsset),
            address(buyerAsset),
            address(buyerContract),
            SELLER_1_DESTINATION_ADDRESS,
            AMOUNT_OF_ASSET_TO_SELL,
            sellerExchangeRate,
            destinationChainSelector
        );
        vm.stopPrank();

        uint256 totalNumberOfPositionsInBuyerContracAfterSwap = buyerContract.getTotalNumberOfOpenPositions();
        console.log(
            "Number of position in buyer contract after swap position creation:",
            totalNumberOfPositionsInBuyerContracAfterSwap
        );

        (
            address sellerAddress,
            uint256 sellingFrom,
            address assetSelling,
            address assetReceiving,
            address sellerReceivingAddress,
            uint8 exchangeRate,
            uint64 destinationChainSelectorFromBuyerContract
        ) = buyerContract.getPositionFromPositionHash(positionHash);

        assertEq(totalNumberOfPositionsInBuyerContractBeforeSwap + 1, totalNumberOfPositionsInBuyerContracAfterSwap);
        assertEq(sellerAddress, SELLER_1);
        assertEq(sellerReceivingAddress, SELLER_1_DESTINATION_ADDRESS);
        assertEq(sellingFrom, sellerContract.CHAIN_ID());
        assertEq(assetSelling, address(sellerAsset));
        assertEq(assetReceiving, address(buyerAsset));
        assertEq(exchangeRate, sellerExchangeRate);
        assertEq(destinationChainSelectorFromBuyerContract, destinationChainSelector);

        vm.prank(SELLER_1);
        assertEq(AMOUNT_OF_ASSET_TO_SELL, sellerContract.getBalanceOfDepositedAsset(address(sellerAsset)));
    }

    function testBuyAsset() public giveSellerSomeAssetToSell(SELLER_1) {
        bytes32 positionHash = createSwapPostion();
        uint256 amountUsedToBuy = 40;
        uint256 amountBuyerShouldReceiveOnDestinationChain = buyerContract.getAmountToReceiveFromBuying(address(sellerAsset), address(buyerAsset), 5, amountUsedToBuy);
        uint256 balanceOfSellerBeforeBuyerBoughtOnDestinationChain = buyerAsset.balanceOf(SELLER_1_DESTINATION_ADDRESS);
        uint256 balanceOfBuyerBeforeBuyingOnDestinationChain = sellerAsset.balanceOf(BUYER_1_DESTINATION_ADDRESS); 

        buyerAsset.drip(BUYER_1);
        vm.startPrank(BUYER_1);

        uint256 balanceOFBuyerBeforeBuyingOnHisOwnChain = buyerAsset.balanceOf(BUYER_1);
        console.log("Balance of buyer before buying:", balanceOFBuyerBeforeBuyingOnHisOwnChain);

        buyerAsset.approve(address(buyerContract), amountUsedToBuy);
        buyerContract.buyAsset(
            positionHash,
            BUYER_1_DESTINATION_ADDRESS,
            address(sellerContract),
            amountUsedToBuy,
            destinationChainSelector
        );

        uint256 balanceOfBuyerAfterBuying = buyerAsset.balanceOf(BUYER_1);
        uint256 balanceOfSellerAfterBuyerBoughtOnDestinationChain = buyerAsset.balanceOf(SELLER_1_DESTINATION_ADDRESS);
        uint256 balanceOfBuyerAfterBuyingOnDestinationChain = sellerAsset.balanceOf(BUYER_1_DESTINATION_ADDRESS);

        console.log("Balance of buyer after buying", balanceOfBuyerAfterBuying);

        assertEq(balanceOfBuyerAfterBuying + amountUsedToBuy, balanceOFBuyerBeforeBuyingOnHisOwnChain);
        assertEq(balanceOfSellerAfterBuyerBoughtOnDestinationChain, balanceOfSellerBeforeBuyerBoughtOnDestinationChain + amountUsedToBuy);
        assertEq(balanceOfBuyerBeforeBuyingOnDestinationChain + amountBuyerShouldReceiveOnDestinationChain, balanceOfBuyerAfterBuyingOnDestinationChain);
        vm.stopPrank();
        vm.prank(SELLER_1);
        assertEq(sellerContract.getBalanceOfDepositedAsset(address(sellerAsset)), AMOUNT_OF_ASSET_TO_SELL - amountBuyerShouldReceiveOnDestinationChain);
    }

    function testGetAssetValueInUsd() public view {
        uint256 expectedValueInUsd = 10e18;
        uint256 actualValueInUsd = sellerContract.getAssetValueInUsd(address(sellerAsset), 1);

        assertEq(expectedValueInUsd, actualValueInUsd);
    }

    function testCalculateAmountToReceiveFromBuying() public view {
        uint256 expectedAmountToReceive = 76;
        uint256 actualAmountToReceive =
            buyerContract.getAmountToReceiveFromBuying(address(sellerAsset), address(buyerAsset), 5, 40);

        assertEq(expectedAmountToReceive, actualAmountToReceive);
    }
}
