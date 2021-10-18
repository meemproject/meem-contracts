# Meem

Join us in building the future of digital content where creators set the rules: [https://discord.gg/5NP8PYN8](https://discord.gg/5NP8PYN8)

## Contract addresses

### Polygon (MATIC) Mainnet

Meem Proxy: [0xb40F5F1bb69C6D30dBa68E0b5f17d7cADA215837](https://rinkeby.etherscan.io/address/0xb40F5F1bb69C6D30dBa68E0b5f17d7cADA215837)

Meem Implementation: [0x20FD5E1e8874704A03F6c7278353BFd62B503192](https://rinkeby.etherscan.io/address/0x20FD5E1e8874704A03F6c7278353BFd62B503192)

MeemPropsLibrary: [0x36E4efAb3953361CaC4BBd284f07C4186906fE22](https://rinkeby.etherscan.io/address/0x36E4efAb3953361CaC4BBd284f07C4186906fE22)


### Rinkeby Testnet

Meem Proxy: [](https://rinkeby.etherscan.io/address/)

Meem Implementation: [](https://rinkeby.etherscan.io/address/)

MeemPropsLibrary: [](https://rinkeby.etherscan.io/address/)

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

#### Deploy MeemPropsLibrary

```yarn deployLib```

#### Deploy Meem URI contract

```yarn deploy --library <MeemPropsLibrary address>```

### Upgrade the contract

```yarn upgradeContract --contractaddress <address> --library <MeemPropsLibrary address>```

## Console Interaction

This will open a hardhat console where you can interact directly with the smart contract

```yarn console```

### Get a meem instance for use in hardhat console

```
const meem = await (await ethers.getContractFactory('Meem', { libraries: { MeemPropsLibrary: '<Library address>' }})).attach('<Contract_address>')
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