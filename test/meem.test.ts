import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, waffle, upgrades } from 'hardhat'
// import MeemArtifact from '../build/Meem.json'
// import MeemPropsLibraryArtifact from '../build/MeemPropsLibrary.json'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemFacet } from '../typechain'

chai.use(chaiAsPromised)

// const { deployContract, link } = waffle

describe('Meem', function Test() {
	let meemFacet: MeemFacet
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
			'MeemFacet',
			DiamondAddress
		)) as MeemFacet
		erc721Facet = (await ethers.getContractAt(
			// 'ERC721Facet',
			process.env.ERC_721_FACET_NAME ?? 'ERC721Facet',
			DiamondAddress
		)) as Erc721Facet
	})

	it('Can get nonOwnerSplitAllocationAmount', async () => {
		const nonOwnerSplitAllocationAmount =
			await meemFacet.nonOwnerSplitAllocationAmount()
		assert.equal(nonOwnerSplitAllocationAmount.toNumber(), 1000)
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
		assert.equal(json.seller_fee_basis_points, 1000)
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

	// it('Can not mint as non-owner', async () => {
	// 	const isMinter = await meemVite.hasRole(
	// 		await meemVite.MINTER_ROLE(),
	// 		signers[1].address
	// 	)

	// 	assert.isFalse(isMinter)

	// 	await assert.isRejected(
	// 		meemVite.connect(signers[1]).mint(signers[1].address)
	// 	)
	// })

	// it('Can get token metadata as anyone', async () => {
	// 	// Mint
	// 	await meemVite.connect(signers[0]).mint(signers[0].address)
	// 	await meemVite.connect(signers[0]).mint(signers[0].address)

	// 	const token0URI = await meemVite.connect(signers[1]).tokenURI(0)
	// 	const token1URI = await meemVite.connect(signers[1]).tokenURI(1)

	// 	const buff0 = Buffer.from(
	// 		token0URI.replace('data:application/json;base64,', ''),
	// 		'base64'
	// 	)

	// 	const json0 = JSON.parse(buff0.toString())
	// 	assert.equal(json0.name, 'MeemVite Seat #0')
	// 	assert.equal(json0.description, 'Join us at https://discord.gg/5NP8PYN8')
	// 	assert.equal(json0.external_url, 'https://meem.wtf/')
	// 	assert.isOk(json0.image)
	// 	assert.equal(json0.background_color, '000000')
	// 	assert.equal(json0.attributes.length, 2)
	// 	const levelAttr0 = json0.attributes.find(
	// 		(a: Record<string, string>) => a.trait_type === 'Level'
	// 	)
	// 	const seatAttr0 = json0.attributes.find(
	// 		(a: Record<string, string>) => a.trait_type === 'Seat'
	// 	)
	// 	assert.equal(levelAttr0.value, 'Ground Floor')
	// 	assert.equal(seatAttr0.value, '0000')

	// 	const buff1 = Buffer.from(
	// 		token1URI.replace('data:application/json;base64,', ''),
	// 		'base64'
	// 	)

	// 	const json1 = JSON.parse(buff1.toString())
	// 	assert.equal(json1.name, 'MeemVite Seat #1')
	// 	assert.equal(json1.description, 'Join us at https://discord.gg/5NP8PYN8')
	// 	assert.equal(json1.external_url, 'https://meem.wtf/')
	// 	assert.isOk(json1.image)
	// 	assert.equal(json1.background_color, '000000')
	// 	assert.equal(json1.attributes.length, 2)
	// 	const levelAttr1 = json1.attributes.find(
	// 		(a: Record<string, string>) => a.trait_type === 'Level'
	// 	)
	// 	const seatAttr1 = json1.attributes.find(
	// 		(a: Record<string, string>) => a.trait_type === 'Seat'
	// 	)
	// 	assert.equal(levelAttr1.value, 'Ground Floor')
	// 	assert.equal(seatAttr1.value, '0001')
	// })

	// it('Can set role as owner and then mint w/ newly granted account', async () => {
	// 	const { status } = await (
	// 		await meemVite
	// 			.connect(signers[0])
	// 			.grantRole(await meemVite.MINTER_ROLE(), signers[1].address)
	// 	).wait()

	// 	assert.equal(status, 1)

	// 	await meemVite.connect(signers[1]).mint(signers[1].address)
	// })

	// it('Can not set role as non-owner', async () => {
	// 	await assert.isRejected(
	// 		meemVite
	// 			.connect(signers[1])
	// 			.grantRole(await meemVite.MINTER_ROLE(), signers[2].address)
	// 	)
	// })

	// it('Can set contractURI as owner', async () => {
	// 	const { status } = await (
	// 		await meemVite
	// 			.connect(signers[0])
	// 			.setContractURI(
	// 				'{"name": "MeemVite Updated","description": "Meems are pieces of digital content wrapped in more advanced dynamic property rights. They are ideas, stories, images -- existing independently from any social platform -- whose creators have set the terms by which others can access, remix, and share in their value. Join us at https://discord.gg/5NP8PYN8","image": "https://meem-assets.s3.amazonaws.com/meem.jpg","external_link": "https://meem.wtf","seller_fee_basis_points": 1000, "fee_recipient": "0x40c6BeE45d94063c5B05144489cd8A9879899592"}'
	// 			)
	// 	).wait()

	// 	assert.equal(status, 1)

	// 	const contractURI = await meemVite.connect(signers[0]).contractURI()
	// 	const buff = Buffer.from(
	// 		contractURI.replace('data:application/json;base64,', ''),
	// 		'base64'
	// 	)

	// 	const json = JSON.parse(buff.toString())
	// 	assert.equal(json.name, 'MeemVite Updated')
	// })

	// it('Can not set contractURI as non-owner', async () => {
	// 	await assert.isRejected(
	// 		meemVite
	// 			.connect(signers[1])
	// 			.setContractURI(
	// 				'{"name": "MeemVite Updated","description": "Meems are pieces of digital content wrapped in more advanced dynamic property rights. They are ideas, stories, images -- existing independently from any social platform -- whose creators have set the terms by which others can access, remix, and share in their value. Join us at https://discord.gg/5NP8PYN8","image": "https://meem-assets.s3.amazonaws.com/meem.jpg","external_link": "https://meem.wtf","seller_fee_basis_points": 1000, "fee_recipient": "0x40c6BeE45d94063c5B05144489cd8A9879899592"}'
	// 			)
	// 	)
	// })

	// it('Can get contractURI as non-owner', async () => {
	// 	const contractURI = await meemVite.connect(signers[0]).contractURI()
	// 	const buff = Buffer.from(
	// 		contractURI.replace('data:application/json;base64,', ''),
	// 		'base64'
	// 	)

	// 	const json = JSON.parse(buff.toString())
	// 	assert.equal(json.name, 'MeemVite')
	// })

	// it('Can set proxy address as owner', async () => {
	// 	const { status } = await (
	// 		await meemVite
	// 			.connect(signers[0])
	// 			.setProxyRegistryAddress('0x58807baD0B376efc12F5AD86aAc70E78ed67deaE')
	// 	).wait()

	// 	assert.equal(status, 1)
	// })

	// it('Can not set proxy address non-owner', async () => {
	// 	await assert.isRejected(
	// 		meemVite
	// 			.connect(signers[1])
	// 			.setProxyRegistryAddress('0x58807baD0B376efc12F5AD86aAc70E78ed67deaE')
	// 	)
	// })
})
