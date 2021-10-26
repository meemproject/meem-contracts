import { getImplementationAddress } from '@openzeppelin/upgrades-core'
import { task, types } from 'hardhat/config'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: (() => Record<string, string>) | Record<string, string>
	waitForConfirmation?: boolean
}

task('upgradeDiamond', 'Upgrade Diamond')
	.addParam('proxy', 'The proxy address', undefined, types.string, false)
	.setAction(async (args, { ethers, upgrades }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const contracts: Record<string, Contract> = {
			Diamond: {}
		}

		const Diamond = await ethers.getContractFactory('Diamond')
		const diamond = await upgrades.upgradeProxy(args.proxy, Diamond, {
			unsafeAllow: ['constructor', 'delegatecall', 'state-variable-assignment']
		})

		await diamond.deployed()
		console.log('Diamond proxy deployed to: ', diamond.address)

		try {
			const implementationAddress = await getImplementationAddress(
				ethers.provider,
				diamond.address
			)

			console.log('Meem implementation deployed to: ', implementationAddress)
		} catch (e) {
			console.log(e)
		}

		return contracts
	})
