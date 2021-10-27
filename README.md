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
    DiamondCutFacet: '0xbd62C82Bde3f60D5E3C36DB0D5D144B6da8325C7',
    DiamondProxy: '0xe308ab2E0864a22ff10B61Ac7f447dd1d6307A63',
    DiamondImplementation: '0xFd5aFd9D94f594Cb95963a56460C868c19f5BC39',
    DiamondLoupeFacet: '0xB16cb6429503Aa529b8F81847EEE4f18cCC8ef4d',
    MeemFacet: '0x7fca3F1325FA0B78D3A6bbE303279daacdF6d6eF'
  }
}
```

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