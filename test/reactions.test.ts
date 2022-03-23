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
	ReactionFacet,
	MeemQueryFacet
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, Permission, UriSource } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Reactions', function Test() {
	let meemFacet: MeemBaseFacet
	let reactionFacet: ReactionFacet
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

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers
		})

		contractAddress = DiamondAddress

		reactionFacet = (await ethers.getContractAt(
			'ReactionFacet',
			contractAddress
		)) as ReactionFacet

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			contractAddress
		)) as MeemBaseFacet

		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet

		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[0].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: true,
					uriSource: UriSource.TokenUri,
					reactionTypes: ['upvote'],
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		const meem = await queryFacet.getMeem(token0)
		assert.equal(meem.reactionTypes[0], 'upvote')
	})

	it('Can add a reaction', async () => {
		const { status } = await (
			await reactionFacet.connect(signers[1]).addReaction(token0, 'upvote')
		).wait()
		assert.equal(status, 1)

		const reactions = await reactionFacet.getReactions(token0)
		assert.equal(reactions[0].reaction, 'upvote')
		assert.equal(reactions[0].count.toNumber(), 1)

		const reactedAt = await reactionFacet.getReactedAt(
			token0,
			signers[1].address,
			'upvote'
		)

		assert.notEqual(reactedAt.toNumber(), 0)
	})

	it('Can remove a reaction', async () => {
		const { status } = await (
			await reactionFacet.connect(signers[1]).removeReaction(token0, 'upvote')
		).wait()
		assert.equal(status, 1)

		const reactions = await reactionFacet.getReactions(token0)
		assert.equal(reactions[0].reaction, 'upvote')
		assert.equal(reactions[0].count.toNumber(), 0)
	})

	it('Can set reaction types as owner', async () => {
		const { status } = await (
			await reactionFacet
				.connect(signers[0])
				.setReactionTypes(token0, ['upvote', 'downvote'])
		).wait()
		assert.equal(status, 1)

		const reactions = await reactionFacet.getReactions(token0)
		assert.equal(reactions[0].reaction, 'upvote')
		assert.equal(reactions[1].reaction, 'downvote')
	})

	it('Can not set reaction types as non-owner', async () => {
		await assert.isRejected(
			reactionFacet
				.connect(signers[1])
				.setReactionTypes(token0, ['upvote', 'downvote'])
		)
	})
})
