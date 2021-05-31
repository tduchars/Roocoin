# Roocoin Token Documentation

I will run through the read functions first, then the write functions. Whenever you write to a blockchain it costs some value. Reading is free, so it can be done as frequently as you like.


### Read Only Functions (free)

- decimals: 18

- masterWallet: 'ethereum wallet address'

- name: RooCoin

- symbol: ROO

- TaxFreeWallets: Takes a ethereum wallet address and returns true or false depending on if that address is whitelisted for having no tax.

- taxPercentage: set to 1% on deployment. Returns current tax rate.

- totalSupply: 100000000000000000000000000 (Due to it being displayed in WEI and not ETH) This is 100million.

- balanceOf: Takes an address and returns the balance of ROO in the address.


### Write Only Functions (paid)

- _burn: Takes an address to burn from and an amount. (in WEI not ETH) Requires that the address we are burning from is not the '0' address. You must have enough tokens in the address to burn and then a transfer to 'address 0' takes place. Can only be called by owner.

- approve: a user calls this function to allow a dapp or dex to act on their behalf.

- changeMasterWalletAddress: Takes a wallet address which will be the current charity address. Can only be called by owner.

- changeTaxPercentage: Takes a new integer which must be equal or above 0 and below 100. Can only be called by owner.

- removeTaxFreeWallet: Takes an ethereum wallet address and removes that wallet from the tax free whitelist. Can only be called by owner.

- setTaxFreeWallet: Takes an address and adds it to the tax free whitelist. Can only be called by owner.

- renounceOwnership: There will no longer be an owner of the contract. Can only be called by owner.

- transfer: Standard erc20 transfer function.

- transferOwnership: Changes the contract owner to the address given to the function. Can only be called by owner.


# BSC TestNet

Roo Token Contract is currently on the binance smart chain testnet. 

https://testnet.bscscan.com/address/0x4Fc18d3286afE908b27488B869D386000644fff7

Possibly, most interestingly the last 4 transactions show me sending a transaction when my wallet is tax-free and the recipient receives 1000. Then when the wallet is not tax-free and a 10% tax of 10 ROO is taken.


