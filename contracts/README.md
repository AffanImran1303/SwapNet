# SwapNet Contracts
The SwapNet uses two different approaches for swapping assets on the different blockchains, which are:
1. P2P Swap
2. Normal Swap

## p2p Swap
This approach enables peer to peer swapping without the help of a liquidity provider. It works more like a market place where sellers earns fees for selling their assets on a different blockchain based on the exchange rate set by the seller which is restricted to 0-5%.

### Here is how it works with an example
James on Polygon chain has a lot of MATIC and wants to sell some for USDC on another chain , let’s say arbitrum chain meaning james wants USDC on arbitrum in exchange for the MATIC he has on Polygon chain. So he uses SwapNet P2p contract deployed on the chain he is on which is polygon chain and calls the function `P2pSwap::createSwapPosition` to create a selling position on the destination chain which is arbitrum , James can decide to add his own exchange rate in form of % from 0-5 so he can earn some fees. He calls this `P2pSwap::createSwapPosition` with the address of the asset he is selling which is MATIC, the address of the assets he wants in exchange of MATIC which is USDC, the destination p2p contract address, exchange rate , amount of the asset he is selling and destination chain selector. 
Then on the other hand , Alison has some USDC tokens on Arbitrum chain but seeks to get MATIC on polygon chain . Alison can see this selling position created by James on Arbitrum chain and decide to exchange her USDC for some MATIC on polygon chain. Then Alison calls the `P2pSwap::buyAsset` function to make this exchange. the amount of MATIC that will be sent to Alison from James account will be determined by the exchange rate set by James and the amount of USDC sent by her.

### Exchange rate calculation
This is how the exchange rate is calculated , so let’s say Alison wants to buy the MATIC James is selling and James' exchange rate is 3%. This means James will remove 3% out of the MATIC he is supposed to give Alison.
So normally with the current price of MATIC/USDC from Chainlink Price feeds, if Alison gives James 10 USDC , then James is supposed to give Alison 50 MATIC, but with this 3% exchange rate that James (the selller) added , Alison wont receive exactly 50 MATIC for her 10 USDC. Alison will be given 3% off from the 50 MATIC that was supposed to be given to her, meaning that alison will receive 1.5 less and that is 50 - 1.5 which is 48.5 MATIC. 48.5 MATIC will be given to alison in exchange for her 10 USDC.

```Javascript
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
```

### Getting Started:
To get started testing the p2p swap contract , you will need to have foundry and all of it's tools installed, follow this link https://book.getfoundry.sh/getting-started/installation to install foundry on your local machine. 

Run this command to install the neccesary dependencies 
```
cd contracts
forge install
npm install
```
Run this command to run the tests
```
cd contracts
forge test --mc P2PSwapTest -vvv
```

**Disclaimer**: This contract works very well with the chainlink simulator and i believe it will work on a live testnet or mainnet but it has not been tested on a mainnet / testnet environment because getting test tokens was realy challenging when we tried testing on a testnet and we wouldn't want to test on a mainnet because that will require real funds. I believe with a little more time and experience we as a team will be able to fully test this implementation of p2p swap on a live testnet, but for the sake of the hackathon submission deadline we will have to submit this project the way it is. 
If you have enough time , you can go through the test contract written for it to make sure you understand in full details how this p2p approach to swap assets on different blockchain works.
