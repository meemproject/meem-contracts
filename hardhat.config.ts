/* eslint-disable @typescript-eslint/no-non-null-assertion */
import dotenv from 'dotenv'
import { HardhatUserConfig } from 'hardhat/config'
import '@nomiclabs/hardhat-waffle'
import '@nomiclabs/hardhat-etherscan'
import '@float-capital/solidity-coverage'
import 'hardhat-typechain'
import 'hardhat-abi-exporter'
import '@openzeppelin/hardhat-upgrades'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'
import './tasks'

dotenv.config()

const config: HardhatUserConfig = {
	solidity: {
		version: '0.8.4',
		settings: {
			optimizer: {
				enabled: true,
				runs: 10_000
			}
		}
	},
	defaultNetwork: 'local',
	networks: {
		mainnet: {
			url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: [process.env.LIVE_WALLET_PRIVATE_KEY!].filter(Boolean)
		},
		xdai: {
			timeout: 120000,
			url: `https://xdai.poanetwork.dev`,
			accounts: process.env.TESTNET_MNEMONIC
				? { mnemonic: process.env.TESTNET_MNEMONIC }
				: [process.env.TESTNET_WALLET_PRIVATE_KEY!].filter(Boolean)
		},
		polygon: {
			timeout: 120000,
			url: 'https://polygon-rpc.com',
			// url: 'https://matic-mainnet-full-rpc.bwarelabs.com',
			// url: 'https://polygon-mainnet.g.alchemy.com/v2/xLwwfjFEFLvv_mRhnv7ZW3qM8f3K8MHE',
			// url: 'https://rpc-mainnet.maticvigil.com',
			// url: 'https://matic-mainnet.chainstacklabs.com',
			// chainId: 137,
			// gasPrice,
			// gasPrice: 40000000000,
			// gas: 75725145187,
			// gasMultiplier: 1.5,
			accounts: process.env.LIVE_MNEMONIC
				? { mnemonic: process.env.LIVE_MNEMONIC }
				: [process.env.LIVE_WALLET_PRIVATE_KEY!].filter(Boolean)
		},
		mumbai: {
			url: 'https://rpc-mumbai.maticvigil.com',
			chainId: 80001,
			gasPrice: 10000000000,
			accounts: process.env.TESTNET_MNEMONIC
				? { mnemonic: process.env.TESTNET_MNEMONIC }
				: [process.env.TESTNET_WALLET_PRIVATE_KEY!].filter(Boolean)
		},
		rinkeby: {
			url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: process.env.TESTNET_MNEMONIC
				? { mnemonic: process.env.TESTNET_MNEMONIC }
				: [process.env.TESTNET_WALLET_PRIVATE_KEY!].filter(Boolean)
		},
		ropsten: {
			url: `https://ropsten.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: process.env.TESTNET_MNEMONIC
				? { mnemonic: process.env.TESTNET_MNEMONIC }
				: [process.env.TESTNET_WALLET_PRIVATE_KEY!].filter(Boolean)
		},
		local: {
			url: 'http://127.0.0.1:8545',
			// gasPrice:
			// 	typeof process.env.LOCAL_GAS_PRICE !== 'undefined'
			// 		? +process.env.LOCAL_GAS_PRICE
			// 		: 65,
			accounts: process.env.LOCAL_MNEMONIC
				? { mnemonic: process.env.LOCAL_MNEMONIC }
				: [process.env.LOCAL_WALLET_PRIVATE_KEY!].filter(Boolean)
		}
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_API_KEY
	},
	abiExporter: {
		path: './abi',
		clear: true
	},
	gasReporter: {
		enabled: !process.env.CI,
		currency: 'USD',
		gasPrice: 66,
		src: 'contracts',
		coinmarketcap: '7643dfc7-a58f-46af-8314-2db32bdd18ba'
	},
	mocha: {
		timeout: 60_000
	}
}
export default config
