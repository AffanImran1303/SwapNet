//SPDX-License-Identifer: MIT
pragma solidity ^0.8.19;

//Importting IERC20 
import "./IERC20.sol";

contract LiquidityProvider{
    //Contract Owner(the user interacting with contract) address
    address public owner;
    //Addresses of Token X and Token Y
    address public tokenX; 
    address public tokenY;

    //Mapping of Liquidity provided by address to their LP token balance 
    mapping (address => uint256) public liquidityA;
    mapping (address => uint256) public liquidityB;

    //To log when a provider adds liquidity.
    //provider => address of the liquidity provider
    //amount => amount to be added
    event LiquidityAdded(address indexed provider, uint256 amount)
    
    //Logs when a provider removes liquidity
    //provider => address of liquidity remover
    //amount => amount to be removed
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    
    //Logs when a token swap is executed
    //user => address of the user who executed the swapped
    //amount => amount of tokenA and tokenB swapped
    event SwapExecuted(address indexed user, uint256 amountA, uint256 amountB);

    //Restricts the access to certain functions, which only contract owner can call
    modifier onlyOwner(){
        require(msg.sender==owner, "Only owner can call this function, SORRY!");
        _;
    }

    //_tokenA and _tokenB addresses of two tokens to be used in liquidity pool
    constructor(address _tokenA, address _tokenB){
        owner=_msg.sender;
        tokenA=_tokenA;
        tokenB=_tokenB;
    }

    //Allows users to add liquidity to the liquidity pool
    function addLiquidity(uint256 amountA, uint256 amountB)external{
        //Move specified amount of tokens from user's address to contract address
        require(IERC20(tokenA).transferFrom(msg.sender,address(this),amountA),"Transfer of tokenA failed");
        require(IERC20(tokenB).transferFrom(msg.sender,address(this),amountB),"Transfer of tokenB failed");

        //Updates internal tracking of liquidity provided by user for tokenA by adding amountA to existing liquidity balance
        liquidityA[msg.sender]+=amountA;

        //Updates internal tracking of liquidity provided by user for tokenB by adding amountB to existing liquidity balance
        liquidityB[msg.sender]+=amountB;

        //Logs address of user, amount of tokenA(amountA) & tokenB(amountB) added
        emit LiquidityAdded(msg.sender,amountA, amountB);
    }

    //Allows users to remove the liquidity from the liquidity pool
    function remmoveLiquidity(uint256 amountA, uint256 amountB)external{
        require(liquidityA[msg.sender]>=amountA, "Insufficient liquidity of token A");
        require(liquidityB[msg.sender]>=amountB, "Insufficient liquidity of token B");

        //Updates the user's liquidity balances by subtracting the withdrawn amounts from their respective balances in pool
        liquidityA[msg.sender]-=amountA;
        liquidityB[msg.sender]-=amountB;

        //Transfers the specified amounts of tokens back to the user
        require(IERC20(tokenA).transfer(msg.sender,amountA),"Transfer of tokenA failed");
        require(IERC20(tokenB).transfer(msg.sender,anountB),"Transfer of tokenB failed");

        //To log the removal of liquidity 
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    //Allows the contract owner to execute a swap between tokens for a user
    //user => Address of user initiating the swap
    //amountA => amount user is swapping
    //amountB => amount user will be receiving 
    function executeSwap(address user, uint256 amountA, uint256 amountB)external{

        //Checks if contract has sufficient liquidity
        require(IERC20(tokenA).transferFrom(user,address(this),amountA),"Transfer of tokenA failed");
        require(IERC20(tokenB).balanceOf(address(this))>=amountB,"Insufficent liquidity of tokenB");

        //Transfers tokenB from contract to user's address
        IERC20(tokenB).transfer(user,amountB);

        //Logs the execution of the swap
        emit SwapExecuted(user,amountA,amountB);
    }
}