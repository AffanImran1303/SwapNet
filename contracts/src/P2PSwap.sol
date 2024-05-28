// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
pragma abicoder v2;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {console} from "forge-std/console.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

import {FeedRegistryInterface} from "@chainlink/brownie/interfaces/FeedRegistryInterface.sol";
import {Denominations} from "@chainlink/brownie/Denominations.sol";

/// @title P2p_SwapNet
/// @author Jeremiah Chinedu
/// @notice Project for chainlink hackathon
/// @dev This is a P2p cross chain swapper that utilizes chainlink cross-chain interoperabilty protocol
contract P2pSwap is CCIPReceiver, OwnerIsCreator {
    // using SafeERC20 for IERC20;

    //////////////
    // Errors
    /////////////
    error P2pSwap__NotEnoughBalance(uint256 contractBalance, uint256 fees);
    error P2pSwap__ExceededNormalExchangeRate();
    error P2pSwap__InsufficientBalanceToWithdraw(uint256 amount);
    error P2pSwap__UnknownError();

    //////////////
    // Events
    /////////////

    // The chain selector of the destination chain.
    // The address of the receiver on the destination chain.
    // The text being sent.
    // The token address that was transferred.
    // The token amount that was transferred.
    // the token address used to pay CCIP fees.
    // The fees paid for sending the message.
    event P2pSwap__MessageSent( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bytes message,
        address feeToken,
        uint256 fees
    );
    event P2pSwap__AssetTransfer(bytes32 indexed messageId, address indexed to, address assetTransfered);
    event P2pSwap__PositionCreated(
        bytes32 indexed messageId,
        address indexed assetToSell,
        address indexed assetToReceive,
        uint64 destinationChainSelector
    );

    struct BuyOrder {
        address buyer;
        address buyerReceivingAddress;
        address seller;
        address sellerReceivingAddress;
        address assetUsedToBuy;
        address assetBought;
        uint256 amountPaid;
        uint256 amountToReceive;
        uint64 buyerChainSelector;
    }

    struct Position {
        address sellerAddress;
        address sellerReceivingAddress; // the destination wallet address of the seller
        uint256 sellingFrom; // chain ID of the blockchain the seller is selling from
        address assetSelling; // the address of the asset the seller is selling
        address assetReceiving; // the address of the asset the seller wants to receive in exchange of the asset he is selling, in otherwords this is the asset the buyer will pay with
        uint8 exchangeRate; // the exchange rate should be between 1-10%
        uint64 destinationChainSelector; // the chainlink destination chain selectorID, i.e the buyer's chainlink chain selector
    }

    /// @notice This holds all the assets available for buying/swapping on the blockchain that this
    /// contract will be deployed on
    /// @dev The position hash will be the keccak256 hash of the created position struct
    mapping(bytes32 positionHash => Position) public s_openPositions;
    uint256 public s_numberOfOpenPositions = 0;

    mapping(address asset => mapping(address seller => uint256 amount)) public s_sellerDepositedAssets;
    FeedRegistryInterface internal feedRegistry;
    uint256 messageGasLimit = 200_000;

    uint256 public immutable CHAIN_ID;
    uint8 constant MAXIMUM_EXCHANGE_RATE = 10;
    uint256 constant DECIMALS = 1e18;

    constructor(address _router, address _registry) CCIPReceiver(_router) {
        feedRegistry = FeedRegistryInterface(_registry);
        CHAIN_ID = block.chainid;
    }

    //////////////////////////////////////
    // public and external functions ////
    /////////////////////////////////////

    /// @notice This function is called by the seller to create a position on the Destionation chain (aka buyer's chain)
    /// @param _sellingAsset This is the asset the seller is willing to sell on the destination chain
    /// @param _receiveingAsset This is the asset the seller will receive on successful swap. This asset will be received on the destination chain
    /// @param _destinationP2pSwapContractAddress This is the address of the p2p swap contract on the destination chain. this contract will act like an escrow to swap the assets
    /// @param _sellerAddress This is the destination address to receive the asset from buyer
    /// @param _amountOfAssetToSell This is the amount of asset a seller is willing to sell
    /// @param _sellingRatePercentage The exchange rate offered by the seller. It shouldn't be above 5%
    /// @param _destinationChainSelector This is the chainlink destination chain selector
    /// @return returns the postion hash, which is the keccak256 hash of the position data
    function createSwapPosition(
        address _sellingAsset,
        address _receiveingAsset,
        address _destinationP2pSwapContractAddress,
        address _sellerAddress,
        uint256 _amountOfAssetToSell,
        uint8 _sellingRatePercentage,
        uint64 _destinationChainSelector
    ) external returns (bytes32) {
        if (_sellingRatePercentage > MAXIMUM_EXCHANGE_RATE) {
            revert P2pSwap__ExceededNormalExchangeRate();
        }

        s_sellerDepositedAssets[_sellingAsset][msg.sender] = _amountOfAssetToSell;
        IERC20(_sellingAsset).transferFrom(msg.sender, address(this), _amountOfAssetToSell);

        Position memory swapPosition = Position({
            sellerAddress: msg.sender,
            sellerReceivingAddress: _sellerAddress,
            sellingFrom: CHAIN_ID,
            assetSelling: _sellingAsset,
            assetReceiving: _receiveingAsset,
            exchangeRate: _sellingRatePercentage,
            destinationChainSelector: _destinationChainSelector
        });

        bytes memory positionData = abi.encode(swapPosition);
        bytes32 positionHash = keccak256(positionData);

        _sendMessage(_destinationChainSelector, _destinationP2pSwapContractAddress, positionData);
        return positionHash;
    }

    /// @notice This is the function the buyer uses to buy asset from a seller
    /// @param _positionHash the hash of a position created by a seller, this might serve as a transaction ID
    /// @param _buyerAddress The destination address the buyer wants to receive the assets in
    /// @param _destinationP2pSwapContractAddress The address of the destionation p2p swap contract, this contract acts as an escrow to swap assets
    /// @param _amount The amount the buyer is willing to pay
    /// @param _destinationChainSelector the chainlink chain selector for destination chain
    function buyAsset(
        bytes32 _positionHash,
        address _buyerAddress,
        address _destinationP2pSwapContractAddress,
        uint256 _amount,
        uint64 _destinationChainSelector
    ) external {
        Position memory position = s_openPositions[_positionHash];
        uint256 amountToReceive =
            _calculateAmountToReceive(position.assetSelling, position.assetReceiving, position.exchangeRate, _amount);
        BuyOrder memory buyOrder = BuyOrder({
            buyer: msg.sender,
            buyerReceivingAddress: _buyerAddress,
            seller: position.sellerAddress,
            sellerReceivingAddress: position.sellerReceivingAddress,
            assetUsedToBuy: position.assetReceiving,
            assetBought: position.assetSelling,
            amountPaid: _amount,
            amountToReceive: amountToReceive,
            buyerChainSelector: position.destinationChainSelector
        });

        IERC20(position.assetReceiving).transferFrom(msg.sender, address(this), _amount);

        _transferAsset(
            _destinationChainSelector,
            _destinationP2pSwapContractAddress,
            position.assetReceiving,
            _amount,
            abi.encode(buyOrder)
        );
    }

    /// @notice A function called by the seller to withdraw deposited assets
    /// @param _asset the address of the asset to be withdrawn
    /// @param _amountToWithdraw the amount to witdraw
    function witdrawAsset(address _asset, uint256 _amountToWithdraw) external {
        if (s_sellerDepositedAssets[_asset][msg.sender] >= _amountToWithdraw) {
            s_sellerDepositedAssets[_asset][msg.sender] -= _amountToWithdraw;
            IERC20(_asset).transfer(msg.sender, _amountToWithdraw);
        }
        revert P2pSwap__InsufficientBalanceToWithdraw(_amountToWithdraw);
    }

    function changeMessageGasLimit(uint256 _newMessageGasLimit) public onlyOwner {
        messageGasLimit = _newMessageGasLimit;
    }

    //////////////////////////////////////
    /// Internal and private functions  //
    /////////////////////////////////////

    /// @notice This function is used to get the amount of asset a buyer will get when transfers a specific amount of his asset
    /// @dev this function takes into consideration the exchange rate added by the seller
    /// @param _sellingAsset the address of the asset to be sold
    /// @param _buyingAsset the address of the asset to be bought
    /// @param _sellerExchangeRate the exchange rate added by the seller
    /// @param _amountToBuy the amount the buyer is depositing/transfering
    /// @return returns the calculated amount
    function _calculateAmountToReceive(
        address _sellingAsset,
        address _buyingAsset,
        uint8 _sellerExchangeRate,
        uint256 _amountToBuy
    ) internal view returns (uint256) {
        uint256 normalExchangeRate = _getNormalExchangeRate(_sellingAsset, _buyingAsset);
        uint256 equivalentAssetForBuyingAsset = _amountToBuy * normalExchangeRate;

        uint256 amountToDeductFromEquivalentAsset = (_sellerExchangeRate * equivalentAssetForBuyingAsset) / 100;
        return equivalentAssetForBuyingAsset - amountToDeductFromEquivalentAsset;
    }

    /// @notice This function is used to get the normal exchange rate of SELLING ASSET/BUYING ASSET
    /// @dev this function uses chainlink oracle to get the latest price of assets
    /// @param _assetA the base asset
    /// @param _assetB the quote asset
    /// @return returns the normal exchange rate
    function _getNormalExchangeRate(address _assetA, address _assetB) internal view returns (uint256) {
        uint8 assetADecimal = feedRegistry.decimals(_assetA, Denominations.USD);
        uint256 priceOfAssetAInUsd = getAssetValueInUsd(_assetA, 1) / (10 ** assetADecimal);

        console.log("Price of seller asset in usd: ", priceOfAssetAInUsd);

        uint8 assetBDecimal = feedRegistry.decimals(_assetB, Denominations.USD);
        uint256 priceOfAssetBInUsd = getAssetValueInUsd(_assetB, 1) / (10 ** assetBDecimal);

        console.log("Price of buyer asset in usd: ", priceOfAssetBInUsd);

        return (priceOfAssetAInUsd) / priceOfAssetBInUsd;
    }

    /// @dev this function handles any message received from cross chain
    /// @dev this is called by the chainlink router
    /// @param message this is the message coming from the cross chain
    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {
        bytes memory receivedMessage = message.data; // abi-decoding of the sent message
        Client.EVMTokenAmount[] memory asset = message.destTokenAmounts;

        if (asset.length == 0 && receivedMessage.length != 0) {
            Position memory swapPosition = abi.decode(receivedMessage, (Position));
            bytes32 swapPositionHash = keccak256(abi.encode(swapPosition));

            s_openPositions[swapPositionHash] = swapPosition;
            emit P2pSwap__PositionCreated(
                message.messageId,
                swapPosition.assetSelling,
                swapPosition.assetReceiving,
                swapPosition.destinationChainSelector
            );
            s_numberOfOpenPositions++;
        } else if (asset.length != 0 && receivedMessage.length != 0) {
            BuyOrder memory buyOrder = abi.decode(receivedMessage, (BuyOrder));

            uint256 sellerAssetAmount = s_sellerDepositedAssets[buyOrder.assetBought][buyOrder.seller];
            console.log("Seller asset: ", buyOrder.assetBought);
            console.log("Buyer amount to receive: ", buyOrder.amountToReceive);
            console.log("Seller amount selling:", sellerAssetAmount);

            if (sellerAssetAmount >= buyOrder.amountToReceive) {
                console.log("Exchaining Assets...");
                s_sellerDepositedAssets[buyOrder.assetBought][buyOrder.seller] -= buyOrder.amountToReceive;
                // send to buyer
                bool success =
                    IERC20(buyOrder.assetBought).transfer(buyOrder.buyerReceivingAddress, buyOrder.amountToReceive);
                if (success) {
                    // send to sender
                    _transferAsset(
                        buyOrder.buyerChainSelector,
                        buyOrder.sellerReceivingAddress,
                        buyOrder.assetUsedToBuy,
                        buyOrder.amountPaid,
                        new bytes(0)
                    );
                }
            } else {
                // refund buyer his asset
                console.log("Refunding Buyer");
                _refundBuyer(buyOrder.buyerChainSelector, buyOrder.buyer, buyOrder.assetUsedToBuy, buyOrder.amountPaid);
            }
        } else {
            revert P2pSwap__UnknownError();
        }
    }

    /// @notice This function refunds the buyer if swap fails
    /// @param _buyerDestinationChainSelector The chainlink chain selector where the buyer is
    /// @param _buyerAddress the address of the buyer
    /// @param _buyerAsset the asset to refund to the buyer
    /// @param _assetAmount the amount to refund
    function _refundBuyer(
        uint64 _buyerDestinationChainSelector,
        address _buyerAddress,
        address _buyerAsset,
        uint256 _assetAmount
    ) internal {
        _transferAsset(_buyerDestinationChainSelector, _buyerAddress, _buyerAsset, _assetAmount, new bytes(0));
    }

    /// @dev This function handles the transfer of asset
    function _transferAsset(
        uint64 _destinationChainSelector,
        address _destinationAddress,
        address _assetAddress,
        uint256 _assetAmount,
        bytes memory data
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(_destinationAddress, _assetAddress, _assetAmount, address(0), data);

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert P2pSwap__NotEnoughBalance(address(this).balance, fees);
        }

        IERC20(_assetAddress).approve(address(router), _assetAmount);
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        emit P2pSwap__AssetTransfer(messageId, _destinationAddress, _assetAddress);

        // Return the message ID
        return messageId;
    }

    /// @dev uses chainlink ccip to send arbitary message to destination chain
    function _sendMessage(
        uint64 _destinationChainSelector,
        address _destinationP2pSwapContractAddress,
        bytes memory _message
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(_destinationP2pSwapContractAddress, address(0), 0, address(0), _message);
        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert P2pSwap__NotEnoughBalance(address(this).balance, fees);
        }
        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        emit P2pSwap__MessageSent(
            messageId, _destinationChainSelector, _destinationP2pSwapContractAddress, _message, address(0), fees
        );
        return messageId;
    }

    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress,
        bytes memory message
    ) private view returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[] memory assetAmount;

        if (_token == address(0)) {
            assetAmount = new Client.EVMTokenAmount[](0);
        } else {
            assetAmount = new Client.EVMTokenAmount[](1);
            assetAmount[0] = Client.EVMTokenAmount({token: _token, amount: _amount});
        }

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        uint256 gasLimitToUse;

        if (message.length == 0) {
            gasLimitToUse = 0;
        } else {
            gasLimitToUse = messageGasLimit;
        }

        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: message, // No data
            tokenAmounts: assetAmount, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: gasLimitToUse})),
            feeToken: _feeTokenAddress
        });
    }

    function getAssetValueInUsd(address _assetAddress, uint256 _amount) public view returns (uint256) {
        (, int256 answer,,,) = feedRegistry.latestRoundData(_assetAddress, Denominations.USD);

        return uint256(answer) * _amount;
    }

    ////////////////////////////////
    // Public and getter functions
    ///////////////////////////////

    function getTotalNumberOfOpenPositions() public view returns (uint256) {
        return s_numberOfOpenPositions;
    }

    function getPositionFromPositionHash(bytes32 positionHash)
        public
        view
        returns (
            address sellerAddress,
            uint256 sellingFrom,
            address assetSelling,
            address assetReceiving,
            address sellerReceivingAddress,
            uint8 exchangeRate,
            uint64 destinationChainSelector
        )
    {
        Position memory position = s_openPositions[positionHash];

        sellerAddress = position.sellerAddress;
        sellingFrom = position.sellingFrom;
        assetSelling = position.assetSelling;
        assetReceiving = position.assetReceiving;
        sellerReceivingAddress = position.sellerReceivingAddress;
        exchangeRate = position.exchangeRate;
        destinationChainSelector = position.destinationChainSelector;
    }

    function getBalanceOfDepositedAsset(address _assetAddress) public view returns (uint256) {
        return s_sellerDepositedAssets[_assetAddress][msg.sender];
    }

    function getAmountToReceiveFromBuying(
        address _sellingAsset,
        address _buyingAsset,
        uint8 _sellerExchangeRate,
        uint256 _amountToBuy
    ) public view returns (uint256) {
        return _calculateAmountToReceive(_sellingAsset, _buyingAsset, _sellerExchangeRate, _amountToBuy);
    }
}
