import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import {
	Erc721Facet,
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

describe('Child root properties', function Test() {
	let meemFacet: MeemBaseFacet
	let meemAdminFacet: MeemAdminFacet
	let erc721Facet: Erc721Facet
	let meemPermissionsFacet: MeemPermissionsFacet
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

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			contractAddress
		)) as MeemBaseFacet

		meemAdminFacet = (await ethers.getContractAt(
			'MeemAdminFacet',
			contractAddress
		)) as MeemAdminFacet

		erc721Facet = (await ethers.getContractAt(
			'ERC721Facet',
			contractAddress
		)) as Erc721Facet

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
					uriSource: UriSource.TokenUri,
					reactionTypes: [],
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)
	}

	it('Can properly sets root info for children of original', async () => {
		await mintZeroMeem()
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: true,
					uriSource: UriSource.TokenUri,
					reactionTypes: [],
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.getMeem(token1)
		assert.equal(meem.root, contractAddress)
		assert.equal(meem.rootTokenId.toNumber(), token0)
	})

	it('Can properly sets root info for children where parent has root set', async () => {
		await mintZeroMeem()
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Ethereum,
					parent: nftAddress,
					parentTokenId: 2000,
					meemType: MeemType.Wrapped,
					data: '',
					isURILocked: true,
					uriSource: UriSource.TokenUri,
					reactionTypes: [],
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: true,
					uriSource: UriSource.TokenUri,
					reactionTypes: [],
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.getMeem(token1)
		assert.equal(meem.root, nftAddress)
		assert.equal(meem.rootChain, Chain.Ethereum)
		assert.equal(meem.rootTokenId.toNumber(), 2000)
	})
})
