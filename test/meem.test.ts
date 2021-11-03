import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, upgrades } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemBaseFacet } from '../typechain'

chai.use(chaiAsPromised)

// const { deployContract, link } = waffle

describe('General MeemFacet Tests', function Test() {
	let meemFacet: MeemBaseFacet
	let erc721Facet: Erc721Facet
	let signers: SignerWithAddress[]

	beforeEach(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers,
			upgrades
		})

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			DiamondAddress
		)) as MeemBaseFacet
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
			'0x40c6BeE45d94063c5B05144489cd8A9879899592'
		)
	})

	it('Can mint as owner', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				'0xde19C037a85A609ec33Fc747bE9Db8809175C3a5',
				'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
				0,
				'0x0000000000000000000000000000000000000000',
				0,
				'0x0000000000000000000000000000000000000000',
				0,
				{
					copyPermissions: [
						{
							permission: 1,
							addresses: [],
							numTokens: 0,
							lockedBy: '0x0000000000000000000000000000000000000000'
						}
					],
					remixPermissions: [
						{
							permission: 1,
							addresses: [],
							numTokens: 0,
							lockedBy: '0x0000000000000000000000000000000000000000'
						}
					],
					readPermissions: [
						{
							permission: 1,
							addresses: [],
							numTokens: 0,
							lockedBy: '0x0000000000000000000000000000000000000000'
						}
					],
					copyPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
					remixPermissionsLockedBy:
						'0x0000000000000000000000000000000000000000',
					readPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
					splits: [
						{
							toAddress: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04',
							amount: 1000,
							lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
						}
					],
					splitsLockedBy: '0x0000000000000000000000000000000000000000',
					childrenPerWallet: -1,
					childrenPerWalletLockedBy:
						'0x0000000000000000000000000000000000000000',
					totalChildren: 99,
					totalChildrenLockedBy: '0x0000000000000000000000000000000000000000'
				},
				{
					copyPermissions: [
						{
							permission: 1,
							addresses: [],
							numTokens: 0,
							lockedBy: '0x0000000000000000000000000000000000000000'
						}
					],
					remixPermissions: [
						{
							permission: 1,
							addresses: [],
							numTokens: 0,
							lockedBy: '0x0000000000000000000000000000000000000000'
						}
					],
					readPermissions: [
						{
							permission: 1,
							addresses: [],
							numTokens: 0,
							lockedBy: '0x0000000000000000000000000000000000000000'
						}
					],
					copyPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
					remixPermissionsLockedBy:
						'0x0000000000000000000000000000000000000000',
					readPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
					splits: [
						{
							toAddress: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04',
							amount: 1000,
							lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
						}
					],
					splitsLockedBy: '0x0000000000000000000000000000000000000000',
					childrenPerWallet: -1,
					childrenPerWalletLockedBy:
						'0x0000000000000000000000000000000000000000',
					totalChildren: 99,
					totalChildrenLockedBy: '0x0000000000000000000000000000000000000000'
				}
			)
		).wait()
		assert.equal(status, 1)
	})
})
