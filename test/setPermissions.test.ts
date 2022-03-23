import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import {
	MeemAdminFacet,
	MeemBaseFacet,
	MeemPermissionsFacet,
	MeemQueryFacet
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import {
	Chain,
	MeemType,
	Permission,
	PermissionType,
	PropertyType,
	UriSource
} from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Set Permissions', function Test() {
	let meemFacet: MeemBaseFacet
	let meemAdminFacet: MeemAdminFacet
	let meemPermissionsFacet: MeemPermissionsFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
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
			contractAddress
		)) as MeemBaseFacet

		meemAdminFacet = (await ethers.getContractAt(
			'MeemAdminFacet',
			contractAddress
		)) as MeemAdminFacet

		meemPermissionsFacet = (await ethers.getContractAt(
			'MeemPermissionsFacet',
			contractAddress
		)) as MeemPermissionsFacet

		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet
	})

	async function mintZeroMeem() {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: true,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)
	}

	it('Can set all permissions', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address],
							costWei: '0'
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [],
							costWei: '0'
						}
					]
				},
				meemMintData
			)
		).wait()

		await (
			await meemPermissionsFacet
				.connect(signers[1])
				.setPermissions(token0, PropertyType.Meem, PermissionType.Copy, [
					{
						permission: Permission.Anyone,
						numTokens: 0,
						lockedBy: zeroAddress,
						addresses: [],
						costWei: '0'
					}
				])
		).wait()

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.properties.copyPermissions.length, 1)
		assert.equal(
			meem.properties.copyPermissions[0].permission,
			Permission.Anyone
		)
	})

	it('Can not set permissions if locked', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address],
							costWei: '0'
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [],
							costWei: '0'
						}
					],
					copyPermissionsLockedBy: owner
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[2])
				.setPermissions(token0, PropertyType.Meem, PermissionType.Copy, [
					{
						permission: Permission.Anyone,
						numTokens: 0,
						lockedBy: zeroAddress,
						addresses: [],
						costWei: '0'
					}
				])
		)
	})

	it('Can not overwrite locked permission', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: owner,
							addresses: [signers[1].address],
							costWei: '0'
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [],
							costWei: '0'
						}
					]
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[2])
				.setPermissions(token0, PropertyType.Meem, PermissionType.Copy, [
					{
						permission: Permission.Anyone,
						numTokens: 0,
						lockedBy: zeroAddress,
						addresses: [],
						costWei: '0'
					}
				])
		)
	})

	it('Can add to permissions w/ locked permission', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: owner,
							addresses: [signers[1].address],
							costWei: '0'
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [],
							costWei: '0'
						}
					]
				},
				meemMintData
			)
		).wait()

		await (
			await meemPermissionsFacet
				.connect(signers[1])
				.setPermissions(token0, PropertyType.Meem, PermissionType.Copy, [
					{
						permission: Permission.Anyone,
						numTokens: 0,
						lockedBy: zeroAddress,
						addresses: [],
						costWei: '0'
					},
					{
						permission: Permission.Addresses,
						numTokens: 0,
						lockedBy: owner,
						addresses: [signers[1].address],
						costWei: '0'
					}
				])
		).wait()

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.properties.copyPermissions.length, 2)
		assert.equal(
			meem.properties.copyPermissions[0].permission,
			Permission.Anyone
		)
		assert.equal(
			meem.properties.copyPermissions[1].permission,
			Permission.Addresses
		)
		assert.equal(meem.properties.copyPermissions[1].addresses.length, 1)
		assert.equal(
			meem.properties.copyPermissions[1].addresses[0],
			signers[1].address
		)
	})

	it('Can not set permissions as non-owner', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address],
							costWei: '0'
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [],
							costWei: '0'
						}
					]
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[2])
				.setPermissions(token0, PropertyType.Meem, PermissionType.Copy, [
					{
						permission: Permission.Anyone,
						numTokens: 0,
						lockedBy: zeroAddress,
						addresses: [],
						costWei: '0'
					}
				])
		)
	})
})
