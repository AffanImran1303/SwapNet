//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {CCIPAssist} from "./CCIPAssist.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

contract CCIPTokenSender is CCIPAssist, OwnerIsCreator{

    using SafeERC20 for IERC20;

    /// initializing an instance of IRouterClient
    IRouterClient internal router;
    constructor(address _router){
        router = IRouterClient(_router);
    }

    /*
     * @notice - send message across chain using CCIP
     * @dev - construct data(of type TransferData) to be sent across chain
            fetch the destination chainselector and TokenHub contract address
            build EVM2AnyMessage
            fetch fee for the transaction using IRouterClient
            approve token transfer
            send message
        @params - _dChain - destination chain name
        @params - _dToken - destination token address
        @params - _transferToken - ccip supported token's address
        @params - _transferTokenAmount - amount of _transferToken to be sent
        @params - _eoa - account to credit the tokens to - the user's EOA
        @return - bytes32 - messageId
    */
    function sendMessage(
        string memory _dChain,
        address _dToken,
        address _transferToken,
        uint256 _transferTokenAmount,
        address _eoa
    ) internal returns(bytes32 messageId){

        TransferData memory data = TransferData({ // constructing the data to be sent across chain
            destChain: _dChain,
            destToken: _dToken,
            account: _eoa
        });

        address receiver = receiverAddress[_dChain]; // fetching the TokenHub contract address
        uint64 destinationChainSelector = chainSelector[_dChain]; // fetching the destination chain selector

        // building the EVM2AnyMessage
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildMessage(data, receiver, _transferToken, _transferTokenAmount);

        uint256 fee = router.getFee(destinationChainSelector, evm2AnyMessage); // fetching fee
        if(fee > address(this).balance){
            revert();
        }

        IERC20(_transferToken).approve(address(router), _transferTokenAmount); // approving token transfer

        messageId = router.ccipSend{value: fee}(destinationChainSelector, evm2AnyMessage); // sending message

    }

    /*
     * @notice - build message to be sent cross chain
     * @dev - this function will build the message to be sent to the router
            create an arry of EVMTokenAmount type and populate with transfer token details
            construct an EVM2AnyMessage and return
        @params - _data - TransferData
        @params - _receiver - address of the receiver
        @params - _transferToken - address of the token to be sent
        @params - _transferTokenAmount - amount of token to be sent
        @return - Client.EVM2AnyMessage
    */
    function _buildMessage(
        TransferData memory _data,
        address _receiver,
        address _transferToken,
        uint256 _transferTokenAmount
    ) private pure returns(Client.EVM2AnyMessage memory){

        Client.EVMTokenAmount[] memory tokenSet = new Client.EVMTokenAmount[](1); // array of EVMTokenAmount type
        tokenSet[0] = Client.EVMTokenAmount({ // popuating with CCIP supported transfer token details
            token:_transferToken, 
            amount: _transferTokenAmount
        });

        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // data to be sent across chain
            data: abi.encode(_data), // address of the receiver contract - destination TokenHub contract
            tokenAmounts: tokenSet, // details of ccip supported transfer token
            feeToken: address(0), // paying in native token
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})) // extra argument of allowable gas limit
        });
    }

}