import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import {
	ClippingFacet,
	Erc721Facet,
	MeemAdminFacet,
	MeemBaseFacet,
	MeemPermissionsFacet,
	MeemQueryFacet
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, UriSource } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Clipping', function Test() {
	let clippingFacet: ClippingFacet
	let meemFacet: MeemBaseFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const nftAddress = '0xaF7Cc059196a09f50632372893617376dAfADFF2'
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

		clippingFacet = (await ethers.getContractAt(
			'ClippingFacet',
			contractAddress
		)) as ClippingFacet

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			contractAddress
		)) as MeemBaseFacet

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

	it('Can clip Meems', async () => {
		await mintZeroMeem()
		await mintZeroMeem()

		const { status } = await (
			await clippingFacet.connect(signers[1]).clip(token0)
		).wait()
		assert.equal(status, 1)

		let clippings = await clippingFacet.addressClippings(signers[1].address)
		assert.equal(clippings.length, 1)
		assert.equal(
			clippings[0].toNumber(),
			ethers.BigNumber.from(token0).toNumber()
		)

		await (await clippingFacet.connect(signers[1]).clip(token1)).wait()
		clippings = await clippingFacet.addressClippings(signers[1].address)
		assert.equal(clippings.length, 2)
		assert.equal(
			clippings[1].toNumber(),
			ethers.BigNumber.from(token1).toNumber()
		)
	})

	it('Can not double clip a Meem', async () => {
		await mintZeroMeem()

		const { status } = await (
			await clippingFacet.connect(signers[1]).clip(token0)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(clippingFacet.connect(signers[1]).clip(token0))
	})

	it('Can get clippers', async () => {
		await mintZeroMeem()

		await (await clippingFacet.connect(signers[1]).clip(token0)).wait()

		await (await clippingFacet.connect(signers[2]).clip(token0)).wait()

		await (await clippingFacet.connect(signers[3]).clip(token0)).wait()

		const clippers = await clippingFacet.clippings(token0)
		assert.equal(clippers.length, 3)
		assert.isTrue(clippers.includes(signers[1].address))
		assert.isTrue(clippers.includes(signers[2].address))
		assert.isTrue(clippers.includes(signers[3].address))
	})

	it('Can un-clip a Meem', async () => {
		await mintZeroMeem()

		const { status } = await (
			await clippingFacet.connect(signers[1]).clip(token0)
		).wait()
		assert.equal(status, 1)

		let clippings = await clippingFacet.addressClippings(signers[1].address)
		assert.equal(clippings.length, 1)
		assert.equal(
			clippings[0].toNumber(),
			ethers.BigNumber.from(token0).toNumber()
		)

		await (await clippingFacet.connect(signers[1]).unClip(token0)).wait()

		clippings = await clippingFacet.addressClippings(signers[1].address)
		assert.equal(clippings.length, 0)
	})
})
