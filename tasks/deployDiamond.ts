import path from 'path'
import { HardhatEthersHelpers } from '@nomiclabs/hardhat-ethers/types'
import { HardhatUpgrades } from '@openzeppelin/hardhat-upgrades'
import { ethers as Ethers } from 'ethers'
import fs from 'fs-extra'
import { task } from 'hardhat/config'
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
	ethers: HardhatEthersHelpers
	upgrades: HardhatUpgrades
	hardhatArguments?: HardhatArguments
}) {
	const { ethers, hardhatArguments } = options
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

	const accounts = await ethers.getSigners()
	const contractOwner = accounts[0]
	console.log('Deploying contracts with the account:', contractOwner.address)

	console.log('Account balance:', (await contractOwner.getBalance()).toString())

	// deploy Diamond
	const Diamond = await ethers.getContractFactory('MeemDiamond')

	const diamond = await Diamond.deploy()

	await diamond.deployed()
	deployedContracts.DiamondProxy = diamond.address

	history[diamond.address] = {}

	// deploy facets
	console.log('')
	console.log('Deploying facets')

	const facets: Record<string, Ethers.Contract | null> = {
		AccessControlFacet: null,
		InitDiamond: null,
		MeemBaseFacet: null,
		MeemPermissionsFacet: null,
		MeemSplitsFacet: null,
		ERC721Facet: null
	}

	const cuts = []
	const facetNames = Object.keys(facets)
	for (const facetName of facetNames) {
		const Facet = await ethers.getContractFactory(facetName, {
			...facets[facetName]
		})
		const facet = await Facet.deploy()
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
	const functionCall = facets.InitDiamond?.interface.encodeFunctionData(
		'init',
		[
			{
				name: 'Meem',
				symbol: 'MEEM',
				childDepth: 1,
				nonOwnerSplitAllocationAmount: 100,
				proxyRegistryAddress,
				contractURI:
					'{"name": "Meem","description": "Meems are pieces of digital content wrapped in more advanced dynamic property rights. They are ideas, stories, images -- existing independently from any social platform -- whose creators have set the terms by which others can access, remix, and share in their value. Join us at https://discord.gg/5NP8PYN8","image": "https://meem-assets.s3.amazonaws.com/meem.jpg","external_link": "https://meem.wtf","seller_fee_basis_points": 100, "fee_recipient": "0x40c6BeE45d94063c5B05144489cd8A9879899592"}'
			}
		]
	)

	const tx = await diamondCut.diamondCut(cuts, diamond.address, functionCall)
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

task('deployDiamond', 'Deploys Meem').setAction(
	async (args, { ethers, upgrades, hardhatArguments }) => {
		const result = await deployDiamond({ ethers, upgrades, hardhatArguments })
		return result
	}
)
