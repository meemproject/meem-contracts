import { task, types } from 'hardhat/config'
import { FacetCutAction, getSelectors } from './lib/diamond'

task('upgradeERC721Facet', 'Upgrade ERC721Facet')
	.addParam(
		'diamond',
		'The address of the deployed diamond',
		undefined,
		types.string,
		false
	)
	.setAction(async (args, { ethers }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const ERC721Facet = await ethers.getContractFactory('ERC721Facet')
		const eRC721Facet = await ERC721Facet.deploy()
		await eRC721Facet.deployed()

		const diamondCut = await ethers.getContractAt('IDiamondCut', args.diamond)
		const tx = await diamondCut.diamondCut(
			[
				{
					facetAddress: eRC721Facet.address,
					action: FacetCutAction.Replace,
					functionSelectors: getSelectors(eRC721Facet)
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
