import path from 'path'
import { HardhatEthersHelpers } from '@nomiclabs/hardhat-ethers/types'
import { ethers as Ethers } from 'ethers'
import fs from 'fs-extra'
import { task, types } from 'hardhat/config'
import { HardhatArguments } from 'hardhat/types'
import {
	FacetCutAction,
	getSelectors,
	IDeployHistoryFacet
} from './lib/diamond'

export interface IDeployHistory {
	[proxyAddress: string]: {
		[facetName: string]: IDeployHistoryFacet & {
			previousDeploys: IDeployHistoryFacet[]
		}
	}
}

export async function deployDiamond(options: {
	args?: {
		gwei: number
	}
	ethers: HardhatEthersHelpers
	hardhatArguments?: HardhatArguments
}) {
	const { args, ethers, hardhatArguments } = options
	const deployedContracts: Record<string, string> = {}
	const network = await ethers.provider.getNetwork()
	const { chainId } = network
	const diamondHistoryPath = path.join(process.cwd(), '.diamond')
	const diamondHistoryFile = path.join(
		process.cwd(),
		'.diamond',
		`${chainId}.json`
	)
	let history: IDeployHistory = {}
	try {
		history = await fs.readJSON(diamondHistoryFile)
	} catch (e) {
		console.log(e)
	}

	const wei = args?.gwei ? args.gwei * 1000000000 : undefined

	const accounts = await ethers.getSigners()
	const contractOwner = accounts[0]
	console.log('Deploying contracts with the account:', contractOwner.address)

	console.log('Account balance:', (await contractOwner.getBalance()).toString())

	// deploy Diamond
	const Diamond = await ethers.getContractFactory('MeemDiamond')

	const diamond = await Diamond.deploy({
		gasPrice: wei
	})

	await diamond.deployed()
	deployedContracts.DiamondProxy = diamond.address

	history[diamond.address] = {}

	// deploy facets
	console.log('')
	console.log('Deploying facets')

	const facets: Record<string, Ethers.Contract | null> = {
		AccessControlFacet: null,
		ClippingFacet: null,
		ERC721Facet: null,
		InitDiamond: null,
		MeemAdminFacet: null,
		MeemBaseFacet: null,
		MeemPermissionsFacet: null,
		MeemQueryFacet: null,
		MeemSplitsFacet: null,
		ReactionFacet: null
	}

	const cuts = []
	const facetNames = Object.keys(facets)
	for (const facetName of facetNames) {
		const Facet = await ethers.getContractFactory(facetName, {
			...facets[facetName]
		})
		const facet = await Facet.deploy({
			gasPrice: wei
		})
		await facet.deployed()
		facets[facetName] = facet
		console.log(`${facetName} deployed: ${facet.address}`)
		deployedContracts[facetName] = facet.address
		const functionSelectors = getSelectors(facet)
		cuts.push({
			facetAddress: facet.address,
			action: FacetCutAction.Add,
			functionSelectors
		})

		const previousDeploys = history[diamond.address][facetName]
			? [
					...history[diamond.address][facetName].previousDeploys,
					{
						address: history[diamond.address][facetName].address,
						functionSelectors:
							history[diamond.address][facetName].functionSelectors
					}
			  ]
			: []

		history[diamond.address][facetName] = {
			address: facet.address,
			functionSelectors,
			previousDeploys
		}
	}

	// upgrade diamond with facets
	console.log('')
	console.log('Diamond Cut:', cuts)
	const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)

	let proxyRegistryAddress = ''
	let walletAddress = ''
	const basisPoints = 100

	switch (hardhatArguments?.network) {
		case 'matic':
		case 'polygon':
			walletAddress = '0x9C5ceC7a99D19a9f1754C202aBA01BBFEDECC561'
			proxyRegistryAddress = '0x58807baD0B376efc12F5AD86aAc70E78ed67deaE'
			break

		case 'rinkeby':
			proxyRegistryAddress = '0xf57b2c51ded3a29e6891aba85459d600256cf317'
			walletAddress = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
			break

		case 'mainnet':
			proxyRegistryAddress = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'
			walletAddress = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
			break

		case 'local':
		default:
			proxyRegistryAddress = '0x0000000000000000000000000000000000000000'
			walletAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
			break
	}

	// call to init function
	const functionCall = facets.InitDiamond?.interface.encodeFunctionData(
		'init',
		[
			{
				name: 'Meem',
				symbol: 'MEEM',
				childDepth: -1,
				nonOwnerSplitAllocationAmount: 0,
				proxyRegistryAddress,
				contractURI: `{"name": "Meem","description": "Meems are pieces of digital content wrapped in more advanced dynamic property rights. They are ideas, stories, images -- existing independently from any social platform -- whose creators have set the terms by which others can access, remix, and share in their value. Join us at https://discord.gg/VTsnW6jUgE","image": "https://meem-assets.s3.amazonaws.com/meem.jpg","external_link": "https://meem.wtf","seller_fee_basis_points": ${basisPoints}, "fee_recipient": "${walletAddress}"}`
			}
		]
	)

	const tx = await diamondCut.diamondCut(cuts, diamond.address, functionCall, {
		gasPrice: wei
	})
	console.log('Diamond cut tx: ', tx.hash)
	const receipt = await tx.wait()
	if (!receipt.status) {
		throw Error(`Diamond upgrade failed: ${tx.hash}`)
	}

	await fs.ensureDir(diamondHistoryPath)
	await fs.writeJSON(diamondHistoryFile, history, {
		flag: 'w'
	})

	console.log({
		deployedContracts
	})

	return deployedContracts
}

task('deployDiamond', 'Deploys Meem')
	.addParam('gwei', 'The gwei price', 31, types.int, true)
	.setAction(async (args, { ethers, hardhatArguments }) => {
		const result = await deployDiamond({ args, ethers, hardhatArguments })
		return result
	})
