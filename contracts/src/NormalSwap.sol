// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
pragma abicoder v2;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {console} from "forge-std/console.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
// import {IERC20} from
//     "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract NormalSwap is CCIPReceiver, OwnerIsCreator {
    /////////////////////
    // Errors
    ////////////////////
    error NormalSwap__NotEnoughBalance(uint256 accountBalance, uint256 amount);

    ISwapRouter immutable swapRouter;
    address public conversionToken = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    uint24 public constant poolFee = 3000;

    struct SwapMessage {
        address destinationAddress;
        address toAsset;
        address fromAsset;
        uint256 amount;
    }

    constructor(address _router, address _swapRouter) CCIPReceiver(_router) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {
        bytes memory receivedMessage = message.data; // abi-decoding of the sent message
        Client.EVMTokenAmount[] memory asset = message.destTokenAmounts;

        SwapMessage memory swapMessage = abi.decode(receivedMessage, (SwapMessage));

        if (asset.length != 0) {
            swapExactInputSingle(
                swapMessage.fromAsset, swapMessage.toAsset, swapMessage.destinationAddress, swapMessage.amount
            );
        }
    }

    function swapAsset(
        address _fromAsset,
        address _toAsset,
        uint256 _amount,
        uint64 _destinationChainSelector,
        address _destinationChainSwapContract,
        address _destinationAddress
    ) external {
        TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amount);
        uint256 amountGottenFromConversion = _convertToken(_fromAsset, _amount);

        SwapMessage memory swapMessage = SwapMessage({
            destinationAddress: _destinationAddress,
            toAsset: _toAsset,
            amount: amountGottenFromConversion,
            fromAsset: conversionToken
        });

        _sendSwapMessage(
            _destinationChainSelector,
            _destinationChainSwapContract,
            swapMessage,
            conversionToken,
            amountGottenFromConversion
        );
    }

    function _sendSwapMessage(
        uint64 _destinationChainSelector,
        address _destinationChainSwapContract,
        SwapMessage memory _swapMessage,
        address _asset,
        uint256 _amount
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(_destinationChainSwapContract, abi.encode(_swapMessage), _asset, _amount, address(0));
        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance) {
            revert NormalSwap__NotEnoughBalance(address(this).balance, fees);
        }

        TransferHelper.safeApprove(_asset, address(router), _amount);
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        // emit MessageSent(
        //     messageId,
        //     _destinationChainSelector,
        //     _receiver,
        //     _text,
        //     _asset,
        //     _amount,
        //     address(0),
        //     fees
        // );

        // Return the message ID
        return messageId;
    }

    function _convertToken(address _fromAsset, uint256 _amountIn) internal returns (uint256) {
        TransferHelper.safeApprove(_fromAsset, address(swapRouter), _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _fromAsset,
            tokenOut: conversionToken,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0, // TODO: Try to use chainlink price oracle to get the value for this
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }

    function swapExactInputSingle(address _fromAsset, address _toAsset, address _recipient, uint256 _amount)
        internal
        returns (uint256)
    {
        TransferHelper.safeApprove(_fromAsset, address(swapRouter), _amount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _fromAsset,
            tokenOut: _toAsset,
            fee: poolFee,
            recipient: _recipient,
            deadline: block.timestamp,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        uint256 amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }

    function changeConversionToken(address _newConversionToken) external onlyOwner {
        conversionToken = _newConversionToken;
    }

    function _buildCCIPMessage(
        address _receiver,
        bytes memory _message,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: _token, amount: _amount});
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _message, // ABI-encoded string
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: 200_000})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
    }
}
