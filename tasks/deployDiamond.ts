// import { getImplementationAddress } from '@openzeppelin/upgrades-core'
import { task } from 'hardhat/config'
import { FacetCutAction, getSelectors } from './lib/diamond'

type ContractName = 'Meem'
// type ContractName = 'Meem' | 'MeemPropsLibrary'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

task('deployDiamond', 'Deploys Meem').setAction(
	async (args, { ethers, upgrades, hardhatArguments }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const accounts = await ethers.getSigners()
		const contractOwner = accounts[0]

		// deploy DiamondCutFacet
		const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
		const diamondCutFacet = await DiamondCutFacet.deploy()
		await diamondCutFacet.deployed()
		console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

		// deploy Diamond
		const Diamond = await ethers.getContractFactory('Diamond')
		const diamond = await Diamond.deploy(
			contractOwner.address,
			diamondCutFacet.address
		)
		await diamond.deployed()
		console.log('Diamond deployed:', diamond.address)

		// deploy DiamondInit
		// DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
		// Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
		const DiamondInit = await ethers.getContractFactory('InitDiamond')
		const diamondInit = await DiamondInit.deploy()
		await diamondInit.deployed()
		console.log('DiamondInit deployed:', diamondInit.address)

		// deploy facets
		console.log('')
		console.log('Deploying facets')
		const FacetNames = ['DiamondLoupeFacet', 'OwnershipFacet', 'MeemFacet']
		const cut = []
		for (const FacetName of FacetNames) {
			const Facet = await ethers.getContractFactory(FacetName)
			const facet = await Facet.deploy()
			await facet.deployed()
			console.log(`${FacetName} deployed: ${facet.address}`)
			cut.push({
				facetAddress: facet.address,
				action: FacetCutAction.Add,
				functionSelectors: getSelectors(facet)
			})
		}

		// upgrade diamond with facets
		console.log('')
		console.log('Diamond Cut:', cut)
		const diamondCut = await ethers.getContractAt(
			'IDiamondCut',
			diamond.address
		)
		// let tx
		// let receipt
		// call to init function
		const functionCall = diamondInit.interface.encodeFunctionData('init', [
			{
				name: 'Meem',
				symbol: 'MEEM'
			}
		])
		console.log({ functionCall })
		const tx = await diamondCut.diamondCut(
			cut,
			diamondInit.address,
			functionCall
		)
		console.log('Diamond cut tx: ', tx.hash)
		const receipt = await tx.wait()
		if (!receipt.status) {
			throw Error(`Diamond upgrade failed: ${tx.hash}`)
		}
		console.log('Completed diamond cut')
		return diamond.address
	}
)
