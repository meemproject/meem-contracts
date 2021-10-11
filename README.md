# MeemVite token

A MeemVite token connects you directly with the MeemDAO team on Discord as a full "Meember".

Join us in building the future of digital content where creators set the rules: [https://discord.gg/5NP8PYN8](https://discord.gg/5NP8PYN8)

## Contract addresses

### Polygon (MATIC) Mainnet

MeemVite Proxy: [0xF503e9A36402F9184211b7DCAf097b5a59923bAF](https://polygonscan.com/address/0xF503e9A36402F9184211b7DCAf097b5a59923bAF)

MeemVite Implementation: [0x824b166E7F6289518c8a694CF6385941a85d58DE](https://polygonscan.com/address/0x824b166E7F6289518c8a694CF6385941a85d58DE)

MeemViteURI: [0xe00400D4b6dd34ACCa34b591F395379B65248503](https://polygonscan.com/address/0xe00400D4b6dd34ACCa34b591F395379B65248503)

Opensea: [https://opensea.io/collection/meemvite](https://opensea.io/collection/meemvite)

### Rinkeby Testnet

MeemVite Proxy: [0x275EeF8f111D2B79cB9C196133d1E1aD0a8710F2](https://rinkeby.etherscan.io/address/0x275EeF8f111D2B79cB9C196133d1E1aD0a8710F2)

MeemVite Implementation: [0x0bfae9bb23c5c7633f37af2928b2ffd5594f4809](https://rinkeby.etherscan.io/address/0x0bfae9bb23c5c7633f37af2928b2ffd5594f4809)

MeemViteURI: [0x1d2fA012f7557025Ac9FE1ADB0D738C4Bf57c1E2](https://rinkeby.etherscan.io/address/0x1d2fA012f7557025Ac9FE1ADB0D738C4Bf57c1E2)

Opensea: [https://testnets.opensea.io/collection/meemvite-testnet](https://testnets.opensea.io/collection/meemvite-testnet)

## Metadata

All metadata is 100% on-chain!

* Metadata standards for opensea: https://docs.opensea.io/docs/metadata-standards

* Contract (opensea collection) standards for opensea: https://docs.opensea.io/docs/contract-level-metadata

## Development

By default all commands will use the local network. For other networks use the ```--network <network_name>``` flag. See the hardhat.config.ts file for network names.

### Set up your .env

Copy the `.env.example` file to .env

### Install dependencies

```yarn```

### Watch and compile files automatically

```yarn watch```

### Run tests

```yarn test```

### Run local blockchain

This will start up a local node using hardhat

```yarn network```

**NEVER SEND ETH TO THESE ADDRESSES EXCEPT ON YOUR LOCAL NETWORK**

## Smart Contract Interaction

> **Change the network**
>
> For (deploy, upgrade, console, etc.) commands, you can change the network with `--network <network name>`
>
> The local network is used by default.

### Deploy contract

**You should only do this the first time. After that you should use upgrade to keep the same address**

#### Deploy MeemVite contract

```yarn deploy```

#### Deploy MeemVite URI contract

```yarn deployURI```

### Upgrade the contract

```yarn upgradeContract --contractaddress <address>```

## Console Interaction

This will open a hardhat console where you can interact directly with the smart contract

```yarn console```

### Get a meem instance for use in hardhat console

```
const meemVite = await (await ethers.getContractFactory('MeemVite')).attach('<Contract_address>')
```

### Set the token URI contract

To properly return the `tokenURI`, the contract of the MeemViteURI address must be set

```
await meemVite.setTokenURIContractAddress(<MeemViteURI address>)
```

### Mint a MeemVite

```
await meem.mint('<To address>')
```

### Get meem metadata uri

```
await meem.tokenURI(<Meem id>)

await meem.tokenURI(0)
```

### Grant a role

Available Roles:

* `DEFAULT_ADMIN_ROLE`
* `PAUSER_ROLE`
* `MINTER_ROLE`
* `UPGRADER_ROLE`

```
await meem.grantRole((await meem.MINTER_ROLE()), '<address>')
```

## Faucets

### Rinkeby

* https://faucet.rinkeby.io/
* https://app.mycrypto.com/faucet
* http://rinkeby-faucet.com/
* https://faucets.blockxlabs.com/ethereum

Offline / Not working consistently
* https://rinkeby.faucet.epirus.io/#


### Ropsten

5 ETH every 24 hours: https://faucet.dimensions.network/

1 ETH but spotty availability: https://faucet.metamask.io/