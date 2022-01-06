import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet } from '../typechain'

chai.use(chaiAsPromised)

// const { deployContract, link } = waffle

describe('General MeemFacet Tests', function Test() {
	// let meemFacet: MeemBaseFacet
	let erc721Facet: Erc721Facet
	let signers: SignerWithAddress[]

	beforeEach(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers
		})

		// meemFacet = (await ethers.getContractAt(
		// 	'MeemBaseFacet',
		// 	DiamondAddress
		// )) as MeemBaseFacet
		erc721Facet = (await ethers.getContractAt(
			// 'ERC721Facet',
			process.env.ERC_721_FACET_NAME ?? 'ERC721Facet',
			DiamondAddress
		)) as Erc721Facet
	})

	it('Can get contractURI', async () => {
		const contractURI = await erc721Facet.contractURI()
		const json = JSON.parse(
			Buffer.from(
				contractURI.replace('data:application/json;base64,', ''),
				'base64'
			).toString('ascii')
		)
		assert.equal(json.name, 'Meem')
		assert.isAbove(json.description.length, 1)
		assert.isAbove(json.image.length, 1)
		assert.isAbove(json.image.length, 1)
		assert.equal(json.seller_fee_basis_points, 100)
		assert.equal(
			json.fee_recipient,
			'0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
		)
	})
})
