import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { MeemBaseFacet, MeemQueryFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, Permission, PermissionType } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Child Meem Minting', function Test() {
	let meemFacet: MeemBaseFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const parent = zeroAddress
	const token0 = 100000
	const token1 = 100001

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers
		})

		contractAddress = DiamondAddress

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			DiamondAddress
		)) as MeemBaseFacet
		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet

		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[0].address,
					mTokenURI:
						'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					parentChain: Chain.Polygon,
					parent,
					parentTokenId: 0,
					permissionType: PermissionType.Copy,
					data: '',
					isVerified: false
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							addresses: [signers[1].address],
							numTokens: 0,
							lockedBy: zeroAddress
						}
					],
					remixPermissions: [
						{
							permission: Permission.Addresses,
							addresses: [signers[1].address],
							numTokens: 0,
							lockedBy: zeroAddress
						}
					]
				},
				{
					...meemMintData,
					splits: [
						...meemMintData.splits,
						{
							toAddress: signers[1].address,
							amount: 100,
							lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
						},
						{
							toAddress: signers[2].address,
							amount: 100,
							lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
						}
					]
				}
			)
		).wait()
		assert.equal(status, 1)
	})

	it('Can not mint child without required splits', async () => {
		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: signers[4].address,
					mTokenURI:
						'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					permissionType: PermissionType.Copy,
					data: '',
					isVerified: false
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Can mint child with required splits', async () => {
		const mintData = {
			...meemMintData,
			splits: [
				...meemMintData.splits,
				{
					toAddress: signers[1].address,
					amount: 100,
					lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
				},
				{
					toAddress: signers[2].address,
					amount: 100,
					lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
				}
			]
		}
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[4].address,
					mTokenURI:
						'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					permissionType: PermissionType.Copy,
					data: '',
					isVerified: false
				},
				mintData,
				mintData
			)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.getMeem(token1)
		console.log({ meem })
	})

	it('Can not mint child as non-approved wallet', async () => {
		const mintData = {
			...meemMintData,
			splits: [
				...meemMintData.splits,
				{
					toAddress: signers[1].address,
					amount: 100,
					lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
				},
				{
					toAddress: signers[2].address,
					amount: 100,
					lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
				}
			]
		}

		await assert.isRejected(
			meemFacet.connect(signers[2]).mint(
				{
					to: signers[4].address,
					mTokenURI:
						'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					permissionType: PermissionType.Copy,
					data: '',
					isVerified: false
				},
				mintData,
				mintData
			)
		)
	})

	it('Can mint child as approved wallet address', async () => {
		const mintData = {
			...meemMintData,
			splits: [
				...meemMintData.splits,
				{
					toAddress: signers[1].address,
					amount: 100,
					lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
				},
				{
					toAddress: signers[2].address,
					amount: 100,
					lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
				}
			]
		}
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					mTokenURI:
						'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					permissionType: PermissionType.Copy,
					data: '',
					isVerified: false
				},
				mintData,
				mintData
			)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.getMeem(token1)
		console.log({ meem })
	})
})
