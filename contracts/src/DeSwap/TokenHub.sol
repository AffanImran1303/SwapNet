//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {CCIPTokenSender} from "./CCIPTokenSender.sol";
import {TokenSwap} from "./TokenSwap.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenHub is CCIPTokenSender {

    using SafeERC20 for IERC20;

    IERC20 token;

    constructor() CCIPTokenSender() {
        super();
    }

    bool private _toSwap;
    bool private _toBridge;
    bool private _toEOA;


    function process(
        address _EOA,
        string memory _sChain,
        string memory _dChain,
        address _sToken,
        address _dToken,
        uint256 _sTokenAmount
    ) external returns(bool) {

        token = IERC20(_sToken);
        token.approve(msg.sender, _sTokenAmount); // approving token transfer
        token.safeTransferFrom(_sToken, msg.sender, address(this), _sTokenAount); // sending source token to this contract
        
        /// comparing the source and destination chains to decide on the need to bridge tokens
        if(keccak256(abi.encodePacked(_sChain)) == keccak256(abi.encodePacked(_dChain))) {
            
            /// comapring the source and destionation token to decide on swapping or sending to EOA
            if(_sToken != _dToken){
                _toSwap = true;
            } else { _toEOA = true; }
        } else {

            _toBridge = true;

            /// comparing the source token against the allowed tokens to decide on swapping
            _toSwap = true;
            for(uint32 i=0; i<allowlist.length; i++){
                if(keccak256(abi.encodePacked(allowlist[i])) == keccak256(abi.encodePacked(_sToken))){
                    toSwap = false;
                    break ;
                }
            }
        }

        /// functionality to swap and then bridge using ccip
        while(_toSwap && _toBridge){

            bool swapResult;
            uint256 amountOUT;
            bool bridgeResult;
            bytes32 messageId;

            address supportToken = allowlist[0]; // fetching pre-defined CCIP supported token address

            (swapResult, amountOUT) = swapAsset(_sChain, supportToken, _sTokenAmount); //swappig with uniswap for CCIP supported token

            require(swapResult && amountOUT);
            _toSwap = false;

            (bridgeresult, messageId) = bridgeAsset(_dChain, _dToken, supportToken, amountOUT, _EOA); // bridging the supported token over to expected blockchain network

            require(bridgeresult && messageId);
            _toBridge = false;

            return true;
        }

        /// functionality to just swap for a different token on the same network
        while(_toSwap && !_toBridge){

            bool swapResult;
            uint256 amountOUT;

            (swapResult, amountOUT) = swapAsset(_sChain, _dToken, _sTokenAmount); // swapping the source token for destination token using uniswap

            require(swapResult && amountOUT);
            _toSwap = false;

            return sendAsset(_dToken, amountOUT, _EOA); // sending the swapped token to the user's EOA

        }

        /// functionality to bridge the supported token using ccip
        while(!_toSwap && _toBridge){

            bool bridgeResult;
            bytes32 messageId;

            (bridgeResult, messageId) = bridgeAsset(_dChain, _dToken, _sToken, _sTokenAmount, _EOA); // bridging the source token to the destination chain 

            require(bridgeResult && messageId);
            _toBridge = false;

            return true;
        }

        /// functionality to send the token over to the EOA
        while(_toEOA){

            require(sendAsset(_sToken, _sTokenAmount, _EOA)); // sending the tokens to the user
            _toEOA = false;
        }
    }

    function bridgeAsset(
        string memory _dChain,
        address _dToken,
        address _transferToken,
        uint256 _transferTokenAmount,
        address _EOA
    ) internal returns(bool, bytes32){
        bytes32 messageId = sendMessage(_dChain, _dToken, _transferToken, _transferTokenAmount, _EOA);
        require(messageId);
        return (true, messageId);
    }

    function swapAsset(
        address _tokenIN,
        address _tokenOUT,
        uint256 _amountIN
    ) internal returns(bool, uint256){
        uint256 amountOUT = TokenSwap.swap(_tokenIN, _tokenOUT, _amountIN);
        require(amountOUT);
        return (true, amountOUT);
    }

    function sendAsset(
        address _token,
        uint256 _amount,
        address _EOA
    ) internal returns(bool){
        IERC20 asset = IERC20(_token);
        require(asset.balanceOf(address(this)) >= _amount , "Insufficient Balance!");
        require(asset.transfer(_EOA, _amount), "Transaction failed");
        return true;
    }

}