import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { MeemBaseFacet, MeemQueryFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, UriSource } from './helpers/meemStandard'

chai.use(chaiAsPromised)

describe('Query Meems', function Test() {
	let meemFacet: MeemBaseFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]
	let contractAddress: string
	// const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
	const parent = '0xc4A383d1Fd38EDe98F032759CE7Ed8f3F10c82B0'
	const token0 = 100000
	// const token1 = 100001
	// const token2 = 100002
	// const token3 = 100003

	before(async () => {
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
		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet
	})

	it('Can query wrapped', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent,
					parentTokenId: 50,
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

		const shouldBeWrapped = await queryFacet.isNFTWrapped(
			Chain.Polygon,
			parent,
			50
		)
		const shouldNotBeWrapped = await queryFacet.isNFTWrapped(
			Chain.Polygon,
			parent,
			51
		)

		assert.isTrue(shouldBeWrapped)
		assert.isFalse(shouldNotBeWrapped)

		const result = await queryFacet.wrappedTokens([
			{
				chain: Chain.Polygon,
				contractAddress: parent,
				tokenId: 50
			},
			{
				chain: Chain.Polygon,
				contractAddress: parent,
				tokenId: 500
			}
		])

		assert.equal(result[0].toNumber(), token0)
		assert.equal(result[1].toNumber(), 0)
	})
})
