//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

//Interface defining the contract external functions, serves as a template for contracts
interface IERC20{

    //recipent => Address to which tokens will be transfered
    //amount => Number of tokens to transfer
    function transfer(address recipent, uint256 amount) external returns (bool);
    
    //sender => Address from which tokens will be transferred
    //recipent => Address to which tokens will be transfere
    //amount => Number of tokens to transfer
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    //account => Address whose balance of token is being checked
    function balanceOf(address account) external view returns(uint256);
}