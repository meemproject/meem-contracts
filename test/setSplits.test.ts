import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import {
	MeemAdminFacet,
	MeemBaseFacet,
	MeemQueryFacet,
	MeemSplitsFacet
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import {
	Chain,
	MeemType,
	PropertyType,
	UriSource
} from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Set Splits', function Test() {
	let meemFacet: MeemBaseFacet
	let meemAdminFacet: MeemAdminFacet
	let meemSplitsFacet: MeemSplitsFacet
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

		meemSplitsFacet = (await ethers.getContractAt(
			'MeemSplitsFacet',
			contractAddress
		)) as MeemSplitsFacet

		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet
	})

	it('Can set splits non-locked', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: zeroAddress
						}
					]
				},
				meemMintData
			)
		).wait()

		await (
			await meemSplitsFacet
				.connect(signers[1])
				.setSplits(token0, PropertyType.Meem, [
					{
						amount: 1000,
						toAddress: owner,
						lockedBy: zeroAddress
					},
					{
						amount: 2000,
						toAddress: signers[0].address,
						lockedBy: zeroAddress
					}
				])
		).wait()

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.properties.splits.length, 2)
		assert.equal(meem.properties.splits[0].toAddress, owner)
		assert.equal(meem.properties.splits[0].amount.toNumber(), 1000)
		assert.equal(meem.properties.splits[0].lockedBy, zeroAddress)
		assert.equal(meem.properties.splits[1].toAddress, signers[0].address)
		assert.equal(meem.properties.splits[1].amount.toNumber(), 2000)
		assert.equal(meem.properties.splits[1].lockedBy, zeroAddress)
	})

	it('Can set splits with locked if included', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: owner
						}
					]
				},
				meemMintData
			)
		).wait()

		await (
			await meemSplitsFacet
				.connect(signers[1])
				.setSplits(token0, PropertyType.Meem, [
					{
						amount: 100,
						toAddress: owner,
						lockedBy: owner
					},
					{
						amount: 2000,
						toAddress: signers[0].address,
						lockedBy: zeroAddress
					}
				])
		).wait()

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.properties.splits.length, 2)
		assert.equal(meem.properties.splits[0].toAddress, owner)
		assert.equal(meem.properties.splits[0].amount.toNumber(), 100)
		assert.equal(meem.properties.splits[0].lockedBy, owner)
		assert.equal(meem.properties.splits[1].toAddress, signers[0].address)
		assert.equal(meem.properties.splits[1].amount.toNumber(), 2000)
		assert.equal(meem.properties.splits[1].lockedBy, zeroAddress)
	})

	it('Can set splits with locked if included - 2', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							toAddress: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04',
							amount: 8000,
							lockedBy: '0x0000000000000000000000000000000000000000'
						},
						{
							toAddress: '0x40c6BeE45d94063c5B05144489cd8A9879899592',
							amount: 500,
							lockedBy: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04'
						}
					]
				},
				meemMintData
			)
		).wait()

		await (
			await meemSplitsFacet
				.connect(signers[1])
				.setSplits(token0, PropertyType.Meem, [
					{
						toAddress: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04',
						amount: 8000,
						lockedBy: '0x0000000000000000000000000000000000000000'
					},
					{
						toAddress: '0x40c6BeE45d94063c5B05144489cd8A9879899592',
						amount: 500,
						lockedBy: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04'
					},
					{
						toAddress: '0xe56067C6Bbbffb30A756486C4b85B12BEA549297',
						amount: 400,
						lockedBy: '0x0000000000000000000000000000000000000000'
					}
				])
		).wait()

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.properties.splits.length, 3)
		// assert.equal(meem.properties.splits[1].toAddress, owner)
		// assert.equal(meem.properties.splits[1].amount.toNumber(), 100)
		// assert.equal(meem.properties.splits[1].lockedBy, owner)
		// assert.equal(meem.properties.splits[0].toAddress, signers[0].address)
		// assert.equal(meem.properties.splits[0].amount.toNumber(), 2000)
		// assert.equal(meem.properties.splits[0].lockedBy, zeroAddress)
		// assert.equal(meem.properties.splits[2].toAddress, signers[3].address)
		// assert.equal(meem.properties.splits[2].amount.toNumber(), 500)
		// assert.equal(meem.properties.splits[2].lockedBy, zeroAddress)
	})

	it('Can not set splits with locked if it does not match', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: owner
						}
					]
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemSplitsFacet.connect(signers[1]).setSplits(token0, PropertyType.Meem, [
				{
					amount: 1000,
					toAddress: owner,
					lockedBy: owner
				},
				{
					amount: 2000,
					toAddress: signers[0].address,
					lockedBy: zeroAddress
				}
			])
		)
	})

	it('Can not set splits with locked if locked item is omitted', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: owner
						}
					]
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemSplitsFacet.connect(signers[1]).setSplits(token0, PropertyType.Meem, [
				{
					amount: 2000,
					toAddress: signers[0].address,
					lockedBy: zeroAddress
				}
			])
		)
	})

	it('Can unlock locked split', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: owner
						}
					]
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemSplitsFacet.connect(signers[1]).setSplits(token0, PropertyType.Meem, [
				{
					amount: 100,
					toAddress: owner,
					lockedBy: zeroAddress
				}
			])
		)
	})

	it('Can not set splits if splits are locked', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: owner
						}
					],
					splitsLockedBy: owner
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemSplitsFacet.connect(signers[1]).setSplits(token0, PropertyType.Meem, [
				{
					amount: 1000,
					toAddress: owner,
					lockedBy: zeroAddress
				},
				{
					amount: 2000,
					toAddress: signers[0].address,
					lockedBy: zeroAddress
				}
			])
		)
	})

	it('Can not set splits as non-owner', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: owner
						}
					]
				},
				meemMintData
			)
		).wait()

		await assert.isRejected(
			meemSplitsFacet.connect(signers[2]).setSplits(token0, PropertyType.Meem, [
				{
					amount: 1000,
					toAddress: owner,
					lockedBy: zeroAddress
				},
				{
					amount: 2000,
					toAddress: signers[0].address,
					lockedBy: zeroAddress
				}
			])
		)
	})

	it('Can lock a split', async () => {
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
					isURILocked: true,
					mintedBy: signers[0].address,
					uriSource: UriSource.TokenUri,
					reactionTypes: []
				},
				{
					...meemMintData,
					splits: [
						{
							amount: 100,
							toAddress: owner,
							lockedBy: zeroAddress
						}
					]
				},
				meemMintData
			)
		).wait()

		await (
			await meemSplitsFacet
				.connect(signers[1])
				.updateSplitAt(token0, PropertyType.Meem, 0, {
					amount: 100,
					toAddress: owner,
					lockedBy: signers[1].address
				})
		).wait()

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.properties.splits.length, 1)
		assert.equal(meem.properties.splits[0].lockedBy, signers[1].address)
	})
})
