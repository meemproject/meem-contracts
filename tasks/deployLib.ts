import { task } from 'hardhat/config'

type ContractName = 'MeemPropsLibrary'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	// libraries?: () => Record<string, string>
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

task('deployLib', 'Deploys MeemPropsLibrary').setAction(
	async (args, { ethers }) => {
		const [deployer] = await ethers.getSigners()
		console.log('Deploying contracts with the account:', deployer.address)

		console.log('Account balance:', (await deployer.getBalance()).toString())

		const MeemPropsLibrary = await ethers.getContractFactory('MeemPropsLibrary')

		const mpl = await MeemPropsLibrary.deploy()
		await mpl.deployed()

		console.log(`Deployed MeemPropsLibrary to: ${mpl.address}`)

		const contracts: Record<ContractName, Contract> = {
			MeemPropsLibrary: {}
		}

		return contracts
	}
)
