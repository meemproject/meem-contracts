import { getImplementationAddress } from '@openzeppelin/upgrades-core'
import { task, types } from 'hardhat/config'

type ContractName = 'Meem'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: (() => Record<string, string>) | Record<string, string>
	waitForConfirmation?: boolean
}

task('upgradeContract', 'Upgrade Meem')
	.addParam(
		'contractaddress',
		'The originally deployed contract address',
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
	.setAction(async (args, { ethers, upgrades }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const contracts: Record<ContractName, Contract> = {
			Meem: {
				libraries: {
					MeemPropsLibrary: args.library
				}
			}
		}

		const Meem = await ethers.getContractFactory('Meem', {
			libraries: {
				MeemPropsLibrary: args.library
			}
		})
		const meem = await upgrades.upgradeProxy(args.contractaddress, Meem)

		await meem.deployed()
		console.log('Meem proxy deployed to: ', meem.address)

		try {
			const implementationAddress = await getImplementationAddress(
				ethers.provider,
				meem.address
			)

			console.log('Meem implementation deployed to: ', implementationAddress)
		} catch (e) {
			console.log(e)
		}

		return contracts
	})
