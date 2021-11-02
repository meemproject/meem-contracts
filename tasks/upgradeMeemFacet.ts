import path from 'path'
import fs from 'fs-extra'
import { task, types } from 'hardhat/config'
import { IDeployHistory } from './deployDiamond'
import {
	FacetCutAction,
	getSelector,
	getSelectors,
	getSighashes
} from './lib/diamond'

type ContractName = 'Meem'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: (() => Record<string, string>) | Record<string, string>
	waitForConfirmation?: boolean
}

task('upgradeMeemFacet', 'Upgrade MeemFacet')
	.addParam('proxy', 'The proxy address', undefined, types.string, false)
	.addParam('contract', 'The contract address', undefined, types.string, false)
	.setAction(async (args, { ethers }) => {
		const network = await ethers.provider.getNetwork()
		const { chainId } = network
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

		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const MeemFacet = await ethers.getContractFactory('MeemFacet')
		const meemFacet = await MeemFacet.deploy()
		await meemFacet.deployed()

		console.log(`Deployed new facet: ${meemFacet.address}`)

		const newSelectors = getSelectors(meemFacet)

		console.log({ newSelectors })

		// const f = 'function tokenIdsOfOwner(address)'
		console.log(getSighashes(['function tokenIdsOfOwner(address)'], ethers))
		// console.log(ethers.utils.Fragment.from(f))

		return

		const diamondCut = await ethers.getContractAt('IDiamondCut', args.proxy)
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
