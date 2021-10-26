import { task, types } from 'hardhat/config'
import { FacetCutAction, getSelectors } from './lib/diamond'

type ContractName = 'Meem'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: (() => Record<string, string>) | Record<string, string>
	waitForConfirmation?: boolean
}

task('upgradeDiamondLoupeFacet', 'Upgrade DiamondLoupeFacet')
	.addParam('proxy', 'The proxy address', undefined, types.string, false)
	.setAction(async (args, { ethers }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const DiamondLoupeFacet = await ethers.getContractFactory(
			'DiamondLoupeFacet',
			{
				libraries: {
					MeemPropsLibrary: args.library
				}
			}
		)
		const diamondLoupeFacet = await DiamondLoupeFacet.deploy()
		await diamondLoupeFacet.deployed()

		const diamondCut = await ethers.getContractAt('IDiamondCut', args.proxy)
		const tx = await diamondCut.diamondCut(
			[
				{
					facetAddress: diamondLoupeFacet.address,
					action: FacetCutAction.Replace,
					functionSelectors: getSelectors(diamondLoupeFacet)
				}
			],
			ethers.constants.AddressZero,
			'0x',
			{ gasLimit: 5000000 }
		)
		console.log('Diamond cut tx:', tx.hash)
		const receipt = await tx.wait()
		if (!receipt.status) {
			throw Error(`Diamond upgrade failed: ${tx.hash}`)
		}
		console.log('Completed diamond cut: ', tx.hash)
	})
