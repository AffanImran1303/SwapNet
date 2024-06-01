# SwapNet
SwapNet is a cross chain asset swapper that aims to facilitate the exchange of digital asset between different blockchain. 

### The problem:
Swapping crypto currencies between blockchains can be a cumbersome and a complex process. Users often need to rely on Centralized Exchanges or complex bridge protocols which can involve High Fees or limited interoperability.


### The Solution: SwapNet (a cross chain asset swapper)
SwapNet takes two different approaches to solving this problem on an EVM compatible chain.
1. P2P Swap: The p2p swap enables peer to peer swapping of assets without the help of a liquidity provider. It is more like a marketplace where users sell a particular amount of their asset on a blockchain (source chain) for a different asset on another blockchain (destination chain) while earning a little fee from the exchange rate they prefer which is always 0-5%. The p2p version of SwapNet uses chainlink CCIP to facilitate the transfer of message and assets across different supported blockchains and chainlink price feeds to get the latest price of an asset.

2. Normal Swap: The normal swap allows users to swap an asset on a source blockchain for another asset on a destination asset with the help of a liquidity provider like uniswap. This version uses Chainlink CCIP , Chainlink price feeds to fetch the current price of an asset and Uniswap V3 protocol to provide liquidity. 


### Technologies Used:
1. Chainlink CCIP : Chainlink Cross chain interoperability protocol for sending assets and messages across different blockchains.
2. Chainlink Price Feeds: For getting the current price of an asset.
3. Uniswap V3 : Liquidity Provider
4. Foundry: For smart contract development and testing
5. Chainlink Local simulator: for testing cross chain interaction locally
6. React: For Front-end development

