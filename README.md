<p align="center">
	<!-- Logo -->
</p>

# The Danu NFT-AMM

Danu is an automated market maker (AMM) for non-fungible tokens (NFTs). The AMM makes use of an off-chain pricing model which computes fair market prices and liquidation prices. The fair market price is statistically determined the optimal price for both buyer and seller. The liquidation price is the fair market price with an added risk premium to protect the liquidity pool and its providers against taking on too much systematic and idiosyncratic risk. A user can choose to instantly sell their NFT to the pool in return for ETH, but also choose to list their NFT for sale for the fair market price and even their own custom price. Liquidity providers of ETH receive commissions for every liquidation the AMM makes and earn passive yield. 

### Future work

Future work includes, but is not limited to: 

- Adding ERC-20 compatibility. 
- Decentralize the pricing engine and oracles.
- Cryptographically sign every price update.
- Conditional orders (e.g. limit orders) to buy and sell NFTs.
- Allowing for optionality between third-party pricing oracles.
- APIs for trading and building on top of the pricing engine and the AMM. Such as integration in NFT games.  


## Why should I care?

Automated market makers (AMMs) are often associated with bonding curves due to its vast success with fungible tokens. With the rise of non-fungible tokens (NFTs) it was only be a matter of time before that same exact method would be copied over to NFTs. The problem with this method is that all NFTs must essentially be treated as fungible tokens, which defeats the purpose of non-fungibility. We decided to venture outside of the conventional method and truly look at what it means to be an automated market maker for NFTs, while maintining non-fugibility for every individual NFT. 

### For NFT traders:
- Trade at statistically determined fair prices, they are automatically live updated for you, so you don't have to worry about that.
- Instantly liquidate your NFT by trading with the liquidity pool. 
- Or simply sell the NFT at your own price.

### For liquidity providers:
- Earn passive yield from every trade the AMM makes.
- Protection from optimally determined liquidation prices.

### For API users:
- Builders can connect directly to the pricing engine to build your products on.
- Traders can send orders and trade over API.

## Structure of the project

The pitch deck can be found in the folder `/pitch`. Including the TeX file, the figures and the data used for generating the figures.

The Smart Contracts can be found in the `/solidity` directory. These include all the contracts used and written during the hackathon, including tests.

The marketplace code can be found in `/marketplace` and is symlinked. 



## Requirements

There are several requirements that need to be met in order to fully utilize the demo. These are:

- A metamask wallet
- GöETH, this can be accessed through one of the faucets, one of which is provided on the demo itself.
- NFT, any ERC-721 NFT would suffice, we have provided an NFT minting faucet as well.


## Disclaimer

## Contact

You can contact us using any of the following methods:

E-mail: hello@danu.fi

[Twitter](https://twitter.com/DanuFinance)

[Discord](https://t.co/pTwstyutvn)

