// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract TokenSwap {

    /// Declaring a variable to call functions in the ISwapRouter interface
    ISwapRouter public immutable swapRouter;

    /// setting the pool fee to 0.3%
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /*
     * @notice - Function to swap tokens
     * @dev - transfer the amount from the caller
            approve the router to spend the amount
            populate the ExactInputSingleParams
     * @params - _tokenIN - address of the input token
     * @params - _tokenOUT - address of the output token
     * @params - _amountIN - amount of input token to be swapped
     * @returns - amountOUT - amount of output token
    */
    function swap(
        address _tokenIN,
        address _tokenOUT,
        uint256 _amountIN
    ) external view returns(unit256 amountOUT){

        /// Transfering the input token amout to this contract from the caller
        TransferHelper.safeTransferFrom(_tokenIN, msg.sender, address(this), _amountIN);

        /// Approving the router to spend the amount
        TransferHelper.safeApprove(_tokenIN, address(swapRouter),  _amountIN);

        ///  Populating ExactInputSingleParams with the necessary swap data
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIN,
            tokenOut: _tokenOUT,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: _amountIN,
            amountOutMinimum: 0,// populate using v3 sdk
            sqrtPriceLimitX96: 0
        });

        /// calling the swap function and returning value of amountOUT
        amountOUT = swapRouter.exactInputSingle(params);

    }

}

