import { HardhatEthersHelpers } from '@nomiclabs/hardhat-ethers/types'
import { task } from 'hardhat/config'
import { FacetCutAction, getSelectors } from './lib/diamond'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

export async function deployDiamond(options: { ethers: HardhatEthersHelpers }) {
	const deployedContracts: Record<string, string> = {}
	const { ethers } = options
	const accounts = await ethers.getSigners()
	const contractOwner = accounts[0]
	console.log('Deploying contracts with the account:', contractOwner.address)

	console.log('Account balance:', (await contractOwner.getBalance()).toString())

	// deploy DiamondCutFacet
	const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
	const diamondCutFacet = await DiamondCutFacet.deploy()
	await diamondCutFacet.deployed()
	deployedContracts.DiamondCutFacet = diamondCutFacet.address
	console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

	// deploy Diamond
	const Diamond = await ethers.getContractFactory('Diamond')
	const diamond = await Diamond.deploy(
		contractOwner.address,
		diamondCutFacet.address
	)
	await diamond.deployed()
	console.log('Diamond deployed:', diamond.address)
	deployedContracts.Diamond = diamond.address

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

	const MeemPropsLibrary = await ethers.getContractFactory('MeemPropsLibrary')

	const mpl = await MeemPropsLibrary.deploy()
	await mpl.deployed()
	deployedContracts.MeemPropsLibrary = mpl.address
	console.log(`MeemPropsLibrary deployed: ${mpl.address}`)

	const facets: Record<string, Contract> = {
		DiamondLoupeFacet: {},
		OwnershipFacet: {},
		MeemFacet: {
			libraries: {
				MeemPropsLibrary: mpl.address
			}
		},
		ERC721Facet: {}
	}

	const cuts = []
	const facetNames = Object.keys(facets)
	for (const facetName of facetNames) {
		const Facet = await ethers.getContractFactory(facetName, {
			...facets[facetName]
		})
		const facet = await Facet.deploy()
		await facet.deployed()
		console.log(`${facetName} deployed: ${facet.address}`)
		deployedContracts[facetName] = facet.address
		cuts.push({
			facetAddress: facet.address,
			action: FacetCutAction.Add,
			functionSelectors: getSelectors(facet)
		})
	}

	// upgrade diamond with facets
	console.log('')
	console.log('Diamond Cut:', cuts)
	const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
	// let tx
	// let receipt
	// call to init function
	const functionCall = diamondInit.interface.encodeFunctionData('init', [
		{
			name: 'Meem',
			symbol: 'MEEM',
			copyDepth: 1,
			nonOwnerSplitAllocationAmount: 1000
		}
	])
	console.log({ functionCall })
	const tx = await diamondCut.diamondCut(
		cuts,
		diamondInit.address,
		functionCall
	)
	console.log('Diamond cut tx: ', tx.hash)
	const receipt = await tx.wait()
	if (!receipt.status) {
		throw Error(`Diamond upgrade failed: ${tx.hash}`)
	}
	console.log('Completed diamond cut')
	console.log({ deployedContracts })
	return deployedContracts
}

task('deployDiamond', 'Deploys Meem').setAction(async (args, { ethers }) => {
	const result = await deployDiamond({ ethers })
	return result
})
