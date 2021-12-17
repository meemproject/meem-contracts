import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemBaseFacet, MeemQueryFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, Permission, PermissionType } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Child Meem Minting', function Test() {
	let meemFacet: MeemBaseFacet
	let queryFacet: MeemQueryFacet
	let erc721Facet: Erc721Facet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const parent = '0xc4A383d1Fd38EDe98F032759CE7Ed8f3F10c82B0'
	const token0 = 100000
	const token1 = 100001
	const token2 = 100002
	const token3 = 100003

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
		erc721Facet = (await ethers.getContractAt(
			// 'ERC721Facet',
			process.env.ERC_721_FACET_NAME ?? 'ERC721Facet',
			DiamondAddress
		)) as Erc721Facet
		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet

		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				signers[0].address,
				'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
				Chain.Polygon,
				parent,
				1000,
				Chain.Polygon,
				parent,
				1000,
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
				},
				PermissionType.Copy
			)
		).wait()
		assert.equal(status, 1)
	})

	it('Can not mint child without required splits', async () => {
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					signers[4].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					zeroAddress,
					0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
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
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[4].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					zeroAddress,
					0,
					mintData,
					mintData,
					PermissionType.Copy
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
			meemFacet
				.connect(signers[2])
				.mint(
					signers[4].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					zeroAddress,
					0,
					mintData,
					mintData,
					PermissionType.Copy
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
			await meemFacet
				.connect(signers[1])
				.mint(
					signers[4].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					zeroAddress,
					0,
					mintData,
					mintData,
					PermissionType.Copy
				)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.getMeem(token1)
		console.log({ meem })
	})
})
