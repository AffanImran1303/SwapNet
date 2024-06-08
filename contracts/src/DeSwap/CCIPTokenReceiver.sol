//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {TokenHub} from "./TokenHub.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

contract CCIPTokenReceiver is CCIPReceiver, TokenHub {

    using SafeERC20 for IERC20;
    
    constructor(address _router) CCIPReceiver(_router) Token() {}

    /*
     * @notice - receive message from CCIP
     * @dev - receive message and call process function in TokenHub
     * @param - _any2EVMMessage - Client.Any2EVMMessage
    */
    function _ccipReceive(Client.Any2EVMMessage memory _any2EVMMessage) internal override {

        bytes32 messageId = _any2EVMMessage.messageId; // message id of the received message
        require(messageId, "Token receive failed");

        TransferData memory tokenData = abi.decode(_any2EVMMessage.data, (TransferData)); // data about the destination token
        address supportToken = _any2EVMMessage.destTokenAmounts[0].token; // transferred token
        uint256 supportTokenAmount = _any2EVMMessage.destTokenAmounts[0].amount; // transferred token amount

        string dChain = tokenData.destChain;
        address dToken = tokenData.destToken;
        address EOA = tokenData.account;

        // processing the recieved data on TokenHub
        bool result = TokenHub.process(EOA, dChain, dChain, supportToken, dToken, supportTokenAmount);
        require(result, "Token process failed");

    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract.
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails.
    /// It should only be callable by the owner of the contract.
    /// @param _beneficiary The address to which the Ether should be sent.
    function withdraw(address _beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;
        require(amount, "Reverted - Nothing to withdraw !");

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = _beneficiary.call{value: amount}("");
        require(sent, "Revert - Failed to Withdraw");
    }

    /// @notice Allows the owner of the contract to withdraw all tokens of a specific ERC20 token.
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param _beneficiary The address to which the tokens will be sent.
    /// @param _token The contract address of the ERC20 token to be withdrawn.
    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount, "Reverted - Nothing to withdraw !");
        
        IERC20(_token).safeTransfer(_beneficiary, amount);
    }

}