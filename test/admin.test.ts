import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, upgrades } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemFacet } from '../typechain'

chai.use(chaiAsPromised)

describe('Contract Admin', function Test() {
	let meemFacet: MeemFacet
	let erc721Facet: Erc721Facet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const parent = '0xc4A383d1Fd38EDe98F032759CE7Ed8f3F10c82B0'

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers,
			upgrades
		})

		contractAddress = DiamondAddress

		meemFacet = (await ethers.getContractAt(
			'MeemFacet',
			DiamondAddress
		)) as MeemFacet
		erc721Facet = (await ethers.getContractAt(
			// 'ERC721Facet',
			process.env.ERC_721_FACET_NAME ?? 'ERC721Facet',
			DiamondAddress
		)) as Erc721Facet
	})

	it('Can set split amount as admin', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).setNonOwnerSplitAllocationAmount(100)
		).wait()
		assert.equal(status, 1)

		const splitAmount = await meemFacet
			.connect(signers[0])
			.nonOwnerSplitAllocationAmount()
		assert.equal(splitAmount.toNumber(), 100)
	})

	it('Can non set split amount as non-admin', async () => {
		await assert.isRejected(
			meemFacet.connect(signers[1]).setNonOwnerSplitAllocationAmount(100)
		)
	})
})
