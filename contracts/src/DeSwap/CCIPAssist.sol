//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract CCIPAssist {

    /// user defined struct for transfering data cross-chain
    struct TransferData{
        string destChain; // destination network name
        address destToken; // expected token's address on the destination network
        address account; // account to credit the tokens to - the user's EOA
    }
    
    ///mappings for chains supporting CCIP
    mapping(string => bool) public allowedChains; // mapping network name to ccip support status
    mapping(string => uint64) public chainSelector; // mapping destination network name to ccip destinationChainSelector
    mapping(string => address) internal receiverAddress; // mapping destination network name to destination TokenHub contract address

    modifier isChainAllowed(string memory _chainName) {
        if(!allowedChains[_chainName]){
            revert();
        }
        _;
    }

    /*
     * @notice - add a new chain that supports CCIP
     * @dev - checks if the chain is already added
            adds the chain by setting its mapping to true
            sets the chainSelector and receiverAddress values
        @params - _chainName - name of the destination chain
        @params - _chainSelector - CCIP destination chain selector
        @params - _receiver - address of the TokenHub contract on destination chain
        @return - bool - true if the chain is added
    */
    function addChain(string memory _chainName, uint64 _chainSelector, address _receiver) external returns(bool){
        if(!allowedChains[_chainName]){
            allowedChains[_chainName] = true;
            chainSelector[_chainName] = _chainSelector;
            receiverAddress[_chainName] = _receiver;
            return allowedChains[_chainName];
        }
    }

    function editChain(string memory _chainName, uint64 _chainSelector) external isChainAllowed(_chainName) returns(bool){
        chainSelector[_chainName] = _chainSelector;
        return allowedChains[_chainName];
    }

    function editChain(string memory _chainName, address _receiver) external isChainAllowed(_chainName) returns(bool){
        receiverAddress[_chainName] = _receiver;
        return allowedChains[_chainName];
    }

    function editChain(string memory _chainName, uint64 _chainSelector, address _receiver) isChainAllowed(_chainName) external returns(bool){
        chainSelector[_chainName] = _chainSelector;
        receiverAddress[_chainName] = _receiver;
        return allowedChains[_chainName];
    }

    function removeChain(string memory _chainName) external isChainAllowed(_chainName) returns(bool){
        allowedChains[_chainName] = false;
        return !allowedChains[_chainName];
    }

    function getChainSelector(string memory _chainName) public view isChainAllowed(_chainName) returns(uint64){
        return chainSelector[_chainName];
    }

    function getReceiver(string memory _chainName) internal view isChainAllowed(_chainName) returns(address){
        return receiverAddress[_chainName];
    }

    mapping(address => bool) allowedTokens; // mapping for tokens allowed on CCIP

    address[] public allowlist; // array of token addresses supported by CCIP

    modifier isTokenAllowed(address _token) {
        if(!allowedTokens[_token]){
            revert();
        }
        _;
    }

    function addToken(address _token) external returns(bool){
        if(!allowedTokens[_token]){
            allowedTokens[_token] = true;
            allowlist.push(_token);
            return allowedTokens[_token];
        }  
    }

    function removeToken(address _token) external isTokenAllowed(_token) returns(bool){
        
        for(uint32 i=0; i<allowlist.length; i++){
            if(keccak256(abi.encodePacked(allowlist[i])) == keccak256(abi.encodePacked(_token))){
				address last = allowlist[allowlist.length-1];
				allowlist[allowlist.length-1] = allowlist[i];
				allowlist[i] = last;
				allowlist.pop();
				break;
			}
        }
        
        allowedTokens[_token] = false;
        return !allowedTokens[_token];
    }


}