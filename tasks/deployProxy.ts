import { task } from 'hardhat/config'

interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	// libraries?: () => Record<string, string>
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

task('deployProxy', 'Deploys MeemProxy').setAction(async (args, { ethers }) => {
	const [deployer] = await ethers.getSigners()
	console.log('Deploying contracts with the account:', deployer.address)

	console.log('Account balance:', (await deployer.getBalance()).toString())

	const MeemProxy = await ethers.getContractFactory('MeemProxy')

	const proxy = await MeemProxy.deploy(
		'0x3784A7dbd1D9E7CeF51204D37346ac9bcc311825',
		deployer.address,
		[]
	)
	await proxy.deployed()

	console.log(`Deployed MeemProxy to: ${proxy.address}`)

	const contracts: Record<string, Contract> = {
		MeemPropsLibrary: {}
	}

	return contracts
})
