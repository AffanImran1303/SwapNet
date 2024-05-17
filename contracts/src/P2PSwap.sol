// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink-ccip/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/ccip/libraries/Client.sol";

import {CCIPReceiver} from "@chainlink-ccip/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink-ccip/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink-ccip/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

import {FeedRegistryInterface} from "@chainlink/interfaces/FeedRegistryInterface.sol";
import {Denominations} from "@chainlink/Denominations.sol";

contract P2pSwap is CCIPReceiver, OwnerIsCreator {
    using SafeERC20 for IERC20;

    //////////////
    // Errors
    /////////////
    error NotEnoughBalance(uint256 contractBalance, uint256 fees);
    error P2pSwap_ExceededNormalExchangeRate();

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
    event MessageSent( // The unique ID of the CCIP message.
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bytes message,
        address feeToken,
        uint256 fees
    );

    event AssetTransfer(bytes32 indexed messageId, address indexed to, address assetTransfered);

    event PositionCreated(
        bytes32 indexed messageId,
        address indexed assetToSell,
        address indexed assetToReceive,
        uint64 destinationChainSelector
    );

    struct Transaction {
        uint256 senderAmount;
        uint256 receiverAmount;
        address senderAsset;
        address receiverAsset;
    }

    struct BuyOrder {
        address buyer;
        address buyerReceivingAddress;
        address seller;
        address assetUsedToBuy;
        address assetBought;
        uint256 amountPaid;
        uint256 amountToReceive;
        uint64 buyerChainSelector;
    }

    struct Escrow {
        address sender;
        address receiver;
        address senderAsset;
        address receiverAsset;
        uint256 senderAmount;
    }

    struct Position {
        address sellerAddress; // the wallet address of the seller
        uint256 sellingFrom; // chain ID of the blockchain the seller is selling from
        address assetSelling; // the address of the asset the seller is selling
        address assetReceiving; // the address of the asset the seller wants to receive in exchange of the asset he is selling, in otherwords this is the asset the buyer will pay with
        uint8 exchangeRate; // the exchange rate should be between 1-10%
        uint64 destinationChainSelector; // the chainlink destination chain selectorID, i.e the buyer's chainlink chain selector
    }

    /// @notice This holds all the assets available for buying/swapping on the blockchain that this
    /// contract will be deployed on
    /// @dev The position hash will be the keccak256 hash of the created position struct
    mapping(bytes32 positionHash => Position) openPositions;

    mapping(bytes32 transactionId => Transaction transaction) private transactions;
    mapping(address asset => mapping(address seller => uint256 amount)) sellerDepositedAssets;
    FeedRegistryInterface internal feedRegistry;
    uint256 messageGasLimit = 200_000;
    IRouterClient router = IRouterClient(this.getRouter());
    uint256 private immutable CHAIN_ID;
    uint8 constant MAXIMUM_EXCHANGE_RATE = 10;
    uint256 constant DECIMALS = 1e18;

    constructor(address _router, address _registry) CCIPReceiver(_router) {
        feedRegistry = FeedRegistryInterface(_registry);
        CHAIN_ID = block.chainid;
    }

    // /// @notice This Function is used to swap a user's asset on a blockChain with another asset on another blockchain
    // /// @dev This contract locks the assets to swap until the other party has released his asset for swapping
    // /// @param _fromAsset the address of the senders asset to swap
    // /// @param _toAsset the address of the receivers asset to swap
    // /// @param _amount the amount of the asset to swap
    // /// @param _recepientAddress the address of the receipient on the destination blockchain
    // /// @param _destinationChainSelector the chainlink chain identifier for the destination blockchain
    // /// @param _destinationP2pSwapContractAddress the destination receiver p2p contract address
    // function swapAssets(
    //     address _fromAsset,
    //     address _toAsset,
    //     uint256 _amount,
    //     address _recepientAddress,
    //     uint64 _destinationChainSelector,
    //     address _destinationP2pSwapContractAddress
    // ) public {
    //     IERC20(_fromAsset).transferFrom(msg.sender, address(this), _amount);

    //     Escrow memory escrowDetails = Escrow({
    //         sender: msg.sender,
    //         receiver: _recepientAddress,
    //         senderAsset: _fromAsset,
    //         receiverAsset: _toAsset,
    //         senderAmount: _amount
    //     });

    //     bytes memory endcodedEscrowDetails = abi.encode(escrowDetails);
    //     bytes32 transactionId = keccak256(endcodedEscrowDetails);

    //     Transaction storage transaction = transactions[transactionId];
    //     transaction.senderAmount = _amount;
    //     transaction.senderAsset = _fromAsset;

    //     _sendMessage(_destinationChainSelector, _destinationP2pSwapContractAddress, abi.encode(transaction));

    //     if (transaction.receiverAsset != address(0) && transaction.receiverAmount != 0) {
    //         IERC20(_fromAsset).approve(address(router), _amount);
    //     }
    // }

    //////////////////////////////////////
    // public and external functions ////
    /////////////////////////////////////
    function createSwapPosition(
        address _sellingAsset,
        address _receiveingAsset,
        address _destinationP2pSwapContractAddress,
        address _sellerAddress,
        uint256 _amountOfAssetToSell,
        uint8 _sellingRatePercentage,
        uint64 _destinationChainSelector
    ) external {
        if(_sellingRatePercentage > MAXIMUM_EXCHANGE_RATE){
            revert P2pSwap_ExceededNormalExchangeRate();
        }

        sellerDepositedAssets[_sellingAsset][msg.sender] = _amountOfAssetToSell;
        IERC20(_sellingAsset).transferFrom(msg.sender, msg.sender, _amountOfAssetToSell);

        Position memory swapPosition = Position({
            sellerAddress: _sellerAddress,
            sellingFrom: CHAIN_ID,
            assetSelling: _sellingAsset,
            assetReceiving: _receiveingAsset,
            exchangeRate: _sellingRatePercentage,
            destinationChainSelector: _destinationChainSelector
        });

        bytes memory positionData = abi.encode(swapPosition);

        _sendMessage(_destinationChainSelector, _destinationP2pSwapContractAddress, positionData);
    }

    function buyAsset(
        bytes32 _positionHash,
        address _buyerAddress,
        address _destinationP2pSwapContractAddress,
        uint256 _amount,
        uint64 _destinationChainSelector
    ) external {
       
        Position memory position = openPositions[_positionHash];
        uint256 amountToReceive = _calculateAmountToReceive(position.assetSelling, position.assetReceiving, position.exchangeRate, _amount);
         BuyOrder memory buyOrder = BuyOrder({
            buyer: msg.sender,
            buyerReceivingAddress: _buyerAddress,
            seller: position.sellerAddress,
            assetUsedToBuy: position.assetReceiving,
            assetBought: position.assetSelling,
            amountPaid: _amount,
            amountToReceive: amountToReceive,
            buyerChainSelector: position.destinationChainSelector
        });
        _transferAsset(_destinationChainSelector, _destinationP2pSwapContractAddress,position.assetReceiving , _amount, abi.encode(buyOrder));
    }

    function changeMessageGasLimit(uint256 _newMessageGasLimit) public onlyOwner {
        messageGasLimit = _newMessageGasLimit;
    }

    //////////////////////////////////////
    /// Internal and private functions  //
    /////////////////////////////////////
    
    function _calculateAmountToReceive(
        address _sellingAsset,
        address _buyingAsset,
        uint8 _sellerExchangeRate,
        uint256 _amountToBuy
    ) internal view  returns (uint256) {
        uint256 normalExchangeRate = _getNormalExchangeRate(_sellingAsset, _buyingAsset);
        uint256 equivalentAssetForBuyingAsset = _amountToBuy * normalExchangeRate;

        uint256 amountToDeductFromEquivalentAsset = (_sellerExchangeRate * equivalentAssetForBuyingAsset)/100;
        return equivalentAssetForBuyingAsset - amountToDeductFromEquivalentAsset;
    }

    function _getNormalExchangeRate(address _assetA, address _assetB) internal view returns (uint256){
        uint8 assetADecimal =  feedRegistry.decimals(_assetA, Denominations.USD);
        uint256 priceOfAssetAInUsd = getAssetValueInUsd(_assetA, 1) / assetADecimal;
        
        uint8 assetBDecimal = feedRegistry.decimals(_assetB, Denominations.USD);
        uint256 priceOfAssetBInUsd = getAssetValueInUsd(_assetB, assetBDecimal);

        return (priceOfAssetAInUsd * DECIMALS)/priceOfAssetBInUsd;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {
        bytes memory receivedMessage = message.data; // abi-decoding of the sent message
        address asset = message.destTokenAmounts[0].token;

        if (asset == address(0) && receivedMessage.length != 0) {
            Position memory swapPosition = abi.decode(receivedMessage, (Position));
            bytes32 swapPositionHash = keccak256(abi.encode(swapPosition));

            openPositions[swapPositionHash] = swapPosition;
        } else if (asset != address(0) && receivedMessage.length != 0) {
            BuyOrder memory buyOrder = abi.decode(receivedMessage, (BuyOrder));
            uint256 sellerAssetAmount = sellerDepositedAssets[buyOrder.assetBought][buyOrder.seller];
            if (sellerAssetAmount >= buyOrder.amountToReceive) {
                sellerDepositedAssets[buyOrder.assetBought][buyOrder.seller] -= buyOrder.amountToReceive;
                bool success = IERC20(buyOrder.assetBought).transfer(buyOrder.buyer, buyOrder.amountToReceive);
                if (success){
                    IERC20(buyOrder.assetUsedToBuy).transfer(buyOrder.seller, buyOrder.amountPaid);
                }
            } else {
                // refund buyer his asset
                _refundBuyer(buyOrder.buyerChainSelector, buyOrder.buyer, buyOrder.assetUsedToBuy, buyOrder.amountPaid);
            }
        } else {
            revert();
        }
    }


    function _refundBuyer(
        uint64 _buyerDestinationChainSelector,
        address _buyerAddress,
        address _buyerAsset,
        uint256 _assetAmount
    ) internal {
        _transferAsset(_buyerDestinationChainSelector, _buyerAddress, _buyerAsset, _assetAmount, new bytes(0));
    }

    function _transferAsset(
        uint64 _destinationChainSelector,
        address _destinationP2pSwapContractAddress,
        address _assetAddress,
        uint256 _assetAmount,
        bytes memory data
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(_destinationP2pSwapContractAddress, _assetAddress, _assetAmount, address(0), data);

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }

        IERC20(_assetAddress).approve(address(router), _assetAmount);
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        emit AssetTransfer(messageId, _destinationP2pSwapContractAddress, _assetAddress);

        // Return the message ID
        return messageId;
    }

    function _sendMessage(
        uint64 _destinationChainSelector,
        address _destinationP2pSwapContractAddress,
        bytes memory _message
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(_destinationP2pSwapContractAddress, address(0), 0, address(0), _message);

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert NotEnoughBalance(address(this).balance, fees);
        }
        messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

        emit MessageSent(
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
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: gasLimitToUse})
                ),
            feeToken: _feeTokenAddress
        });
    }

    function getAssetValueInUsd(address _assetAddress, uint256 _amount) internal view returns (uint256) {
        (, int256 answer,,,) = feedRegistry.latestRoundData(_assetAddress, Denominations.USD);

        return uint256(answer) * _amount;
    }
}