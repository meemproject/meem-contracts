import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import {
	MeemPermissionsFacet,
	MeemBaseFacet,
	MeemQueryFacet
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import {
	Chain,
	MeemType,
	PermissionType,
	PropertyType,
	UriSource
} from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Token Owner Permissions', function Test() {
	let meemPermissionsFacet: MeemPermissionsFacet
	let meemFacet: MeemBaseFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]

	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
	const token0 = 100000

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers
		})

		meemPermissionsFacet = (await ethers.getContractAt(
			'MeemPermissionsFacet',
			DiamondAddress
		)) as MeemPermissionsFacet

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			DiamondAddress
		)) as MeemBaseFacet

		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			DiamondAddress
		)) as MeemQueryFacet

		const { status } = await (
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
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)
	})

	it('Can set total copies as owner', async () => {
		const { status } = await (
			await meemPermissionsFacet
				.connect(signers[1])
				.setTotalCopies(token0, PropertyType.Meem, 5000)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.connect(signers[1]).getMeem(token0)
		console.log({ meem })
		assert.equal(meem.properties.totalCopies.toNumber(), 5000)
	})

	it('Can not set total copies as non-owner', async () => {
		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[2])
				.setTotalCopies(token0, PropertyType.Meem, 5000)
		)
	})

	it('Can lock total copies as owner', async () => {
		const { status } = await (
			await meemPermissionsFacet
				.connect(signers[1])
				.lockTotalCopies(token0, PropertyType.Meem)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[1])
				.setTotalCopies(token0, PropertyType.Meem, 5000)
		)
	})

	it('Can set total copies per wallet as owner', async () => {
		const { status } = await (
			await meemPermissionsFacet
				.connect(signers[1])
				.setCopiesPerWallet(token0, PropertyType.Meem, 1)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.connect(signers[1]).getMeem(token0)
		console.log({ meem })
		assert.equal(meem.properties.totalCopies.toNumber(), 5000)
	})

	it('Can not set total copies per wallet as non-owner', async () => {
		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[2])
				.setCopiesPerWallet(token0, PropertyType.Meem, 5000)
		)
	})

	it('Can lock total copies per wallet as owner', async () => {
		const { status } = await (
			await meemPermissionsFacet
				.connect(signers[1])
				.lockCopiesPerWallet(token0, PropertyType.Meem)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(
			meemPermissionsFacet
				.connect(signers[1])
				.setCopiesPerWallet(token0, PropertyType.Meem, 5000)
		)
	})
})
