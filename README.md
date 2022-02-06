# Meem

Join us in building the future of digital content where creators set the rules: [https://meem.wtf](https://meem.wtf)

**Check out the [Developer Documentation](https://developer.meem.wtf/)** for the latest documentation on working with the Meem smart contracts.

## Contract addresses

### Polygon (MATIC) Mainnet

Proxy contract: [0x82aC441F3276ede5db366704866d2E0fD9c2cFA8](https://polygonscan.com/address/0x82aC441F3276ede5db366704866d2E0fD9c2cFA8)

Diamond inspector: [https://louper.dev/diamond/0x82aC441F3276ede5db366704866d2E0fD9c2cFA8?network=matic](https://louper.dev/diamond/0x82aC441F3276ede5db366704866d2E0fD9c2cFA8?network=matic)


### Rinkeby Testnet

Proxy contract: [0x87e5882fa0ea7e391b7e31E8b23a8a38F35C84Ac](https://rinkeby.etherscan.io/address/0x87e5882fa0ea7e391b7e31E8b23a8a38F35C84Ac)

Diamond inspector: [https://louper.dev/diamond/0x87e5882fa0ea7e391b7e31E8b23a8a38F35C84Ac?network=rinkeby](https://louper.dev/diamond/0x87e5882fa0ea7e391b7e31E8b23a8a38F35C84Ac?network=rinkeby)

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

**Options for deploy/upgrade scripts:**
- `--network <network name>` (optional, default is local)
- `--gwei <amount>` (optional)

### Deploy contract

**You should only do this the first time. After that you should use upgrade to keep the same address**

`yarn deployDiamond`

### Upgrade scripts

Upgrade individual facets

`yarn upgradeFacet --proxy <DiamondProxyAddress> --facet <FacetName>`

For example:

`yarn upgradeFacet --proxy 0x26291175Fa0Ea3C8583fEdEB56805eA68289b105 --facet MeemFacet`

### Generate combined ABI

Generate the `abi/Meem.json` file which combines all facets into a single definition. This ABI can then be used in other applications to make requests to the contract.

`yarn createMeemABI`

## Console Interaction

This will open a hardhat console where you can interact directly with the smart contract

```yarn console```

### Get a meem instance for use in hardhat console

```
const meem = await (await ethers.getContractFactory('MeemFacet')).attach('<Contract_address>')
```
