# Meem

Join us in building the future of digital content where creators set the rules: [https://discord.gg/5NP8PYN8](https://discord.gg/5NP8PYN8)

**Check out the [Developer Documentation](https://developer.meem.wtf/)** for the latest documentation on working with the Meem smart contracts.

## Contract addresses

### Polygon (MATIC) Mainnet

Meem Proxy: [](https://polygonscan.com/address/)

Meem Implementation: [](https://polygonscan.com/address/)

MeemPropsLibrary: [](https://polygonscan.com/address/)

```
{
  deployedContracts: {
    DiamondProxy: '0xbbc36838b7b9C5A052f51477FEA23F1Ec4aAcf0c',
    AccessControlFacet: '0xE43B2C94170D019aa70D67d5D88E9D71AAc7eB41',
    ERC721Facet: '0xab21bE5C64134D739b24B8509cb04C4747425360',
    InitDiamond: '0x4C43e2554e71Fb1ff66e1Dd9F6886Eb01455B559',
    MeemAdminFacet: '0x1B5062905613885e61D82b54A7EB316eeDCd6eC5',
    MeemBaseFacet: '0x089F1f6EC208412DAf8c391De21FCaF126a6f8Ca',
    MeemPermissionsFacet: '0x20e3132a5968C9265Fb7Af476dCC1a2B281e9D70',
    MeemQueryFacet: '0xEC1763C310fBAbdA82898771038ce67BD0128E98',
    MeemSplitsFacet: '0x9ff2359b0aDcf5Eba72b3907b2a33255605d6e92'
  }
}
```


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
