import { getImplementationAddress } from '@openzeppelin/upgrades-core'
import { task, types } from 'hardhat/config'

type ContractName = 'Meem'
// type ContractName = 'Meem' | 'MeemPropsLibrary'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

task('deploy', 'Deploys Meem')
	.addParam(
		'library',
		'The MeemPropsLibrary address',
		undefined,
		types.string,
		false
	)
	.setAction(async (args, { ethers, upgrades, hardhatArguments }) => {
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

		// This is the OpenSea proxy address which will allow trading to work properly
		let proxyRegistryAddress = ''

		switch (hardhatArguments.network) {
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

		const Meem = await ethers.getContractFactory('Meem', {
			libraries: {
				MeemPropsLibrary: args.library
			}
		})

		const meem = await upgrades.deployProxy(Meem, [proxyRegistryAddress], {
			kind: 'uups',
			unsafeAllow: ['external-library-linking']
		})

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
