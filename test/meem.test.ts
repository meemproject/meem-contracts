import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, waffle } from 'hardhat'
// import MeemArtifact from '../build/Meem.json'
// import MeemPropsLibraryArtifact from '../build/MeemPropsLibrary.json'
import { deployDiamond } from '../tasks'
import {
	DiamondCutFacet,
	DiamondLoupeFacet,
	MeemFacet,
	OwnershipFacet
} from '../typechain'

chai.use(chaiAsPromised)

// const { deployContract, link } = waffle

describe('Meem', function Test() {
	let meemFacet: MeemFacet
	let diamondAddress
	let diamondCutFacet: DiamondCutFacet
	let diamondLoupeFacet: DiamondLoupeFacet
	let ownershipFacet: OwnershipFacet
	let signers: SignerWithAddress[]

	beforeEach(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		diamondAddress = await deployDiamond({ ethers })
		diamondCutFacet = (await ethers.getContractAt(
			'DiamondCutFacet',
			diamondAddress
		)) as DiamondCutFacet
		diamondLoupeFacet = (await ethers.getContractAt(
			'DiamondLoupeFacet',
			diamondAddress
		)) as DiamondLoupeFacet
		ownershipFacet = (await ethers.getContractAt(
			'OwnershipFacet',
			diamondAddress
		)) as OwnershipFacet
		meemFacet = (await ethers.getContractAt(
			'MeemFacet',
			diamondAddress
		)) as MeemFacet
	})

	it('Can do basic access', async () => {
		const name = await meemFacet.name()
		console.log({ name })
		// const result = await (await meem.connect(signers[0])).name()
		// console.log({ result })
		// assert.isTrue(true)
		// assert.equal(status, 1)
	})

	// it('Can mint as owner', async () => {
	// 	const { status } = await (
	// 		await meem.connect(signers[0]).mint(signers[0].address)
	// 	).wait()
	// 	assert.equal(status, 1)
	// })

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
