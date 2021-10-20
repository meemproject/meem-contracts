import { task, types } from 'hardhat/config'
import { FacetCutAction, getSelectors } from './lib/diamond'

type ContractName = 'Meem'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: (() => Record<string, string>) | Record<string, string>
	waitForConfirmation?: boolean
}

task('upgradeMeemFacet', 'Upgrade MeemFacet')
	.addParam(
		'diamond',
		'The address of the deployed diamond',
		undefined,
		types.string,
		false
	)
	.addParam(
		'library',
		'The MeemPropsLibrary address',
		undefined,
		types.string,
		false
	)
	.setAction(async (args, { ethers }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const MeemFacet = await ethers.getContractFactory('MeemFacet', {
			libraries: {
				MeemPropsLibrary: args.library
			}
		})
		const meemFacet = await MeemFacet.deploy()
		await meemFacet.deployed()

		// const diamondInit = await ethers.getContractAt(
		// 	'InitDiamond',
		// 	args.diamondinit
		// )

		// const functionCall = diamondInit.interface.encodeFunctionData('init', [
		// 	{
		// 		name: 'Meem',
		// 		symbol: 'MEEM',
		// 		copyDepth: 1,
		// 		nonOwnerSplitAllocationAmount: 1000
		// 	}
		// ])

		const diamondCut = await ethers.getContractAt('IDiamondCut', args.diamond)
		const tx = await diamondCut.diamondCut(
			[
				{
					facetAddress: meemFacet.address,
					action: FacetCutAction.Replace,
					functionSelectors: getSelectors(meemFacet)
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
