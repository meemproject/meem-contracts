import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { MeemAdminFacet, MeemBaseFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, Permission, PermissionType } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Minting Permissions', function Test() {
	let meemFacet: MeemBaseFacet
	let meemAdminFacet: MeemAdminFacet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const token0 = 100000
	const token1 = 100001
	const token2 = 100002
	// const token3 = 100003

	beforeEach(async () => {
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

		meemAdminFacet = (await ethers.getContractAt(
			'MeemAdminFacet',
			DiamondAddress
		)) as MeemAdminFacet
	})

	async function mintZeroMeem() {
		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					zeroAddress,
					0,
					Chain.Polygon,
					zeroAddress,
					0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()
		assert.equal(status, 1)
	}

	it('Mints can not exceed childDepth', async () => {
		await mintZeroMeem()

		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()
		assert.equal(status, 1)

		const m1 = await meemFacet.getMeem(token1)
		assert.equal(m1.generation.toNumber(), 1)

		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token1,
					Chain.Polygon,
					contractAddress,
					token1,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)
	})

	it('Increases child depth and generation is updated properly', async () => {
		await mintZeroMeem()
		await (await meemAdminFacet.setChildDepth(2)).wait()

		// First gen
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Second gen
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token1,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		const m2 = await meemFacet.getMeem(token2)
		assert.equal(m2.generation.toNumber(), 2)

		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token2,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)
	})

	it('Respects total children', async () => {
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					zeroAddress,
					0,
					Chain.Polygon,
					zeroAddress,
					0,
					{ ...meemMintData, totalChildren: 1 },
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Succeeds as first child
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					{ ...meemMintData, totalChildren: 1 },
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Fails as second child
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					{ ...meemMintData, totalChildren: 1 },
					meemMintData,
					PermissionType.Copy
				)
		)
	})

	it('Respects children per wallet', async () => {
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					zeroAddress,
					0,
					Chain.Polygon,
					zeroAddress,
					0,
					{ ...meemMintData, childrenPerWallet: 1 },
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Succeeds as first child
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[1].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Fails as second child per wallet
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					signers[1].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)

		// Succeeds as different owner
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[2].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()
	})

	it('Respects owner only minting', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				owner,
				'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
				Chain.Polygon,
				zeroAddress,
				0,
				Chain.Polygon,
				zeroAddress,
				0,
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: []
						}
					]
				},
				meemMintData,
				PermissionType.Copy
			)
		).wait()

		// Succeeds as owner
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Fails as non-owner
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					signers[1].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)
	})

	it('Respects address only minting', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				owner,
				'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
				Chain.Polygon,
				zeroAddress,
				0,
				Chain.Polygon,
				zeroAddress,
				0,
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address]
						}
					]
				},
				meemMintData,
				PermissionType.Copy
			)
		).wait()

		// Succeeds as approved address
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[1].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Fails as owner
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)

		// Fails as other address
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					signers[3].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)
	})

	it('Allows multiple permissions', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				owner,
				'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
				Chain.Polygon,
				zeroAddress,
				0,
				Chain.Polygon,
				zeroAddress,
				0,
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address]
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: []
						}
					]
				},
				meemMintData,
				PermissionType.Copy
			)
		).wait()

		// Succeeds as approved address
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[1].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Succeeds as owner
		await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		).wait()

		// Fails as other address
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					signers[3].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					Chain.Polygon,
					contractAddress,
					token0,
					Chain.Polygon,
					contractAddress,
					token0,
					meemMintData,
					meemMintData,
					PermissionType.Copy
				)
		)
	})
})
