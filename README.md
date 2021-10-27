# Meem

Join us in building the future of digital content where creators set the rules: [https://discord.gg/5NP8PYN8](https://discord.gg/5NP8PYN8)

## Contract addresses

### Polygon (MATIC) Mainnet

Meem Proxy: [](https://polygonscan.com/address/)

Meem Implementation: [](https://polygonscan.com/address/)

MeemPropsLibrary: [](https://polygonscan.com/address/)


### Rinkeby Testnet

```
{
  deployedContracts: {
    DiamondCutFacet: '0x5A6A75a1Ea30f1D564bb36DE45292a236d74A98E',
    DiamondProxy: '0xEBf9B4f3AeEEb1aEFbAf535DC8E353809a7Df6D4',
    DiamondImplementation: '0x197b0716c9e260f9c7bC48781A7e59d6Dc15E513',
    DiamondLoupeFacet: '0x27CCb33F5b7eec52A85c5dfE6eec4388fCe349E9',
    MeemFacet: '0x80897317b9C8D9273b451688121D471c46844d51'
  }
}
```

https://testnets.opensea.io/collection/meem-96ugziir6d

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

### Mint a meem example

```
await meem.mint('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', '', 0, '0x0000000000000000000000000000000000000000', 0, {"copyPermissions": [{"permission": 1, "addresses": [], "numTokens": 0, "lockedBy": "0x0000000000000000000000000000000000000000"}], "remixPermissions": [{"permission": 1, "addresses": [], "numTokens": 0, "lockedBy": "0x0000000000000000000000000000000000000000"}], "readPermissions": [{"permission": 1, "addresses": [], "numTokens": 0, "lockedBy": "0x0000000000000000000000000000000000000000"}], "copyPermissionsLockedBy": "0x0000000000000000000000000000000000000000", "remixPermissionsLockedBy": "0x0000000000000000000000000000000000000000", "readPermissionsLockedBy": "0x0000000000000000000000000000000000000000", "splits": [{"toAddress": "0xbA343C26ad4387345edBB3256e62f4bB73d68a04", "amount": 1000, "lockedBy": "0x0000000000000000000000000000000000000000"}], "splitsLockedBy": "0x0000000000000000000000000000000000000000", "totalCopies": 99, "totalCopiesLockedBy": "0x0000000000000000000000000000000000000000"}, {"copyPermissions": [{"permission": 1, "addresses": [], "numTokens": 0, "lockedBy": "0x0000000000000000000000000000000000000000"}], "remixPermissions": [{"permission": 1, "addresses": [], "numTokens": 0, "lockedBy": "0x0000000000000000000000000000000000000000"}], "readPermissions": [{"permission": 1, "addresses": [], "numTokens": 0, "lockedBy": "0x0000000000000000000000000000000000000000"}], "copyPermissionsLockedBy": "0x0000000000000000000000000000000000000000", "remixPermissionsLockedBy": "0x0000000000000000000000000000000000000000", "readPermissionsLockedBy": "0x0000000000000000000000000000000000000000", "splits": [{"toAddress": "0xbA343C26ad4387345edBB3256e62f4bB73d68a04", "amount": 1000, "lockedBy": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"}], "splitsLockedBy": "0x0000000000000000000000000000000000000000", "totalCopies": 99, "totalCopiesLockedBy": "0x0000000000000000000000000000000000000000"})
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