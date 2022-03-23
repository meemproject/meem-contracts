import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemBaseFacet, MeemQueryFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, UriSource } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Minting', function Test() {
	let meemFacet: MeemBaseFacet
	let queryFacet: MeemQueryFacet
	let erc721Facet: Erc721Facet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
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
	})

	it('Can not mint original with mismatched meemType', async () => {
		await assert.isRejected(
			meemFacet.connect(signers[1]).mint(
				{
					to: owner,
					tokenURI: ipfsURL,
					parentChain: Chain.Ethereum,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Copy,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Can mint original verified as minter role', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[4].address,
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

		const totalSupply = await erc721Facet.connect(signers[0]).totalSupply()
		assert.equal(totalSupply.toNumber(), 1)

		const token0Owner = await erc721Facet.connect(signers[0]).ownerOf(token0)
		assert.equal(token0Owner, signers[4].address)
		const ownerBalance = await erc721Facet
			.connect(signers[0])
			.balanceOf(signers[4].address)
		assert.equal(ownerBalance.toNumber(), 1)

		const tokenIds = await queryFacet
			.connect(signers[0])
			.tokenIdsOfOwner(signers[4].address)

		assert.equal(tokenIds[0].toNumber(), token0)

		// const m = await queryFacet.getMeem(token0)
		// assert.equal(m.verifiedBy, signers[0].address)
	})

	it('Can not transfer wMeem as non-admin', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[2].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Ethereum,
					parent,
					parentTokenId: 0,
					meemType: MeemType.Wrapped,
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

		const totalSupply = await erc721Facet.connect(signers[2]).totalSupply()
		assert.equal(totalSupply.toNumber(), 2)

		const token1Owner = await erc721Facet.connect(signers[2]).ownerOf(token1)
		assert.equal(token1Owner, signers[2].address)
		const ownerBalance = await erc721Facet
			.connect(signers[2])
			.balanceOf(signers[2].address)
		assert.equal(ownerBalance.toNumber(), 1)

		const tokenIds = await queryFacet
			.connect(signers[2])
			.tokenIdsOfOwner(signers[2].address)

		assert.equal(tokenIds[0].toNumber(), token1)

		const meem = await queryFacet.connect(signers[2]).getMeem(token1)
		console.log({ meem, zero: meem[0] })
		assert.equal(meem.owner, signers[2].address)

		await assert.isRejected(
			erc721Facet
				.connect(signers[2])
				.transferFrom(signers[2].address, owner, token1)
		)
	})

	it('Can transfer wMeem as admin', async () => {
		const transferResult = await (
			await erc721Facet
				.connect(signers[0])
				.transferFrom(signers[2].address, owner, token1)
		).wait()
		assert.equal(transferResult.status, 1)
	})

	it('Can create and transfer child meem', async () => {
		const m = await queryFacet.getMeem(token0)
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[2].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		let meem = await queryFacet.connect(signers[2]).getMeem(token2)
		assert.equal(meem.generation.toNumber(), 1)
		console.log({ meem, contractAddress })
		assert.equal(meem.owner, signers[2].address)
		assert.equal(meem.parent, contractAddress)
		assert.equal(meem.root, contractAddress)

		const ca = await erc721Facet.contractAddress()
		console.log({ contractAddress: ca })

		const transferResult = await (
			await erc721Facet
				.connect(signers[2])
				.transferFrom(signers[2].address, owner, token2)
		).wait()
		assert.equal(transferResult.status, 1)

		meem = await queryFacet.connect(signers[2]).getMeem(token2)
		console.log({ meem, contractAddress })
		assert.equal(meem.owner, owner)
		assert.equal(meem.parent, contractAddress)
		assert.equal(meem.root, contractAddress)

		const o = await erc721Facet.ownerOf(token2)
		assert.equal(o, owner)
	})

	it('Can transfer original meem', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[0].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Ethereum,
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

		const totalSupply = await erc721Facet.connect(signers[0]).totalSupply()
		assert.equal(totalSupply.toNumber(), 4)

		const transferResult = await (
			await erc721Facet
				.connect(signers[0])
				.transferFrom(signers[0].address, owner, token3)
		).wait()
		assert.equal(transferResult.status, 1)
	})

	it('Can not mint meem w/ same external parent address', async () => {
		const otherAddress = '0xb822D949E8bE99bb137e04e548CF2fDc88513543'
		// First one can mint
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[0].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Ethereum,
					parent: otherAddress,
					parentTokenId: 1,
					meemType: MeemType.Wrapped,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		// Second one fails
		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					tokenURI: ipfsURL,
					parentChain: Chain.Ethereum,
					parent: otherAddress,
					parentTokenId: 1,
					meemType: MeemType.Copy,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Can check if nft has been wrapped in a meem', async () => {
		const otherAddress = '0xb822D949E8bE99bb137e04e548CF2fDc88513543'

		const isWrapped = await queryFacet
			.connect(signers[0])
			.isNFTWrapped(Chain.Ethereum, otherAddress, 1)

		assert.isTrue(isWrapped)
	})

	it('Can check if nft has not been wrapped in a meem', async () => {
		const otherAddress = '0xb822D949E8bE99bb137e04e548CF2fDc88513543'

		const isWrapped = await queryFacet
			.connect(signers[0])
			.isNFTWrapped(Chain.Ethereum, otherAddress, 2)

		assert.isFalse(isWrapped)
	})

	it('Can mint multiple children', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[5].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[5].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
	})

	it('Can not burn token as non-owner', async () => {
		await assert.isRejected(erc721Facet.connect(signers[1]).burn(token0))
	})

	it('Can burn token as owner', async () => {
		await erc721Facet.connect(signers[4]).burn(token0)
		const tokenIds = await queryFacet
			.connect(signers[0])
			.tokenIdsOfOwner(signers[4].address)

		assert.equal(tokenIds.length, 0)

		const burnedTokenIds = await queryFacet
			.connect(signers[0])
			.tokenIdsOfOwner(zeroAddress)
		assert.equal(burnedTokenIds[0].toNumber(), token0)
	})
})
