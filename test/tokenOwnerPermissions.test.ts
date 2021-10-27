import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, upgrades } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Token Owner Permissions', function Test() {
	let meemFacet: MeemFacet
	let erc721Facet: Erc721Facet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'

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

		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[1].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					0,
					zeroAddress,
					0,
					zeroAddress,
					0,
					meemMintData,
					meemMintData
				)
		).wait()
		assert.equal(status, 1)
	})

	it('Can set total children as owner', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).setTotalChildren(0, 5000)
		).wait()
		assert.equal(status, 1)

		const meem = await meemFacet.connect(signers[1]).getMeem(0)
		console.log({ meem })
		assert.equal(meem.properties.totalChildren.toNumber(), 5000)
	})

	it('Can not set total children as non-owner', async () => {
		await assert.isRejected(
			meemFacet.connect(signers[2]).setTotalChildren(0, 5000)
		)
	})

	it('Can lock total children as owner', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).lockTotalChildren(0)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(
			meemFacet.connect(signers[1]).setTotalChildren(0, 5000)
		)
	})

	it('Can set total children per wallet as owner', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).setChildrenPerWallet(0, 1)
		).wait()
		assert.equal(status, 1)

		const meem = await meemFacet.connect(signers[1]).getMeem(0)
		console.log({ meem })
		assert.equal(meem.properties.totalChildren.toNumber(), 5000)
	})

	it('Can not set total children per wallet as non-owner', async () => {
		await assert.isRejected(
			meemFacet.connect(signers[2]).setChildrenPerWallet(0, 5000)
		)
	})

	it('Can lock total children per wallet as owner', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).lockChildrenPerWallet(0)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(
			meemFacet.connect(signers[1]).setChildrenPerWallet(0, 5000)
		)
	})
})
