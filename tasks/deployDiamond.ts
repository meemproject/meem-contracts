import { HardhatEthersHelpers } from '@nomiclabs/hardhat-ethers/types'
import { task } from 'hardhat/config'
import { HardhatArguments } from 'hardhat/types'
import { FacetCutAction, getSelectors } from './lib/diamond'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

export async function deployDiamond(options: {
	ethers: HardhatEthersHelpers
	hardhatArguments?: HardhatArguments
}) {
	const deployedContracts: Record<string, string> = {}
	const { ethers, hardhatArguments } = options
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

	let proxyRegistryAddress = ''

	switch (hardhatArguments?.network) {
		case 'matic':
		case 'polygon':
			proxyRegistryAddress = '0x58807baD0B376efc12F5AD86aAc70E78ed67deaE'
			break

		case 'rinkeby':
			proxyRegistryAddress = '0xf57b2c51ded3a29e6891aba85459d600256cf317'
			break

		case 'mainnet':
			proxyRegistryAddress = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'
			break

		case 'local':
		default:
			proxyRegistryAddress = '0x0000000000000000000000000000000000000000'
			break
	}

	// call to init function
	const functionCall = diamondInit.interface.encodeFunctionData('init', [
		{
			name: 'Meem',
			symbol: 'MEEM',
			copyDepth: 1,
			nonOwnerSplitAllocationAmount: 1000,
			proxyRegistryAddress
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

task('deployDiamond', 'Deploys Meem').setAction(
	async (args, { ethers, hardhatArguments }) => {
		const result = await deployDiamond({ ethers, hardhatArguments })
		return result
	}
)
