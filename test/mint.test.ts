import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, upgrades } from 'hardhat'
import { deployDiamond } from '../tasks'
import { Erc721Facet, MeemFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Meem', function Test() {
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

	it('Can not mint as non-owner', async () => {
		await assert.isRejected(
			meemFacet
				.connect(signers[1])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					0,
					zeroAddress,
					0,
					zeroAddress,
					0,
					meemMintData,
					meemMintData
				)
		)
	})

	it('Can mint as owner', async () => {
		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					owner,
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

		const totalSupply = await erc721Facet.connect(signers[0]).totalSupply()
		assert.equal(totalSupply.toNumber(), 1)

		const token0Owner = await erc721Facet.connect(signers[0]).ownerOf(0)
		assert.equal(token0Owner, owner)
		const ownerBalance = await erc721Facet.connect(signers[0]).balanceOf(owner)
		assert.equal(ownerBalance.toNumber(), 1)

		const tokenIds = await meemFacet.connect(signers[0]).tokenIdsOfOwner(owner)

		assert.equal(tokenIds[0].toNumber(), 0)
	})

	it('Can not transfer wMeem', async () => {
		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[0].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					0,
					parent,
					0,
					parent,
					0,
					meemMintData,
					meemMintData
				)
		).wait()
		assert.equal(status, 1)

		const totalSupply = await erc721Facet.connect(signers[0]).totalSupply()
		assert.equal(totalSupply.toNumber(), 2)

		const token0Owner = await erc721Facet.connect(signers[0]).ownerOf(1)
		assert.equal(token0Owner, signers[0].address)
		const ownerBalance = await erc721Facet
			.connect(signers[0])
			.balanceOf(signers[0].address)
		assert.equal(ownerBalance.toNumber(), 1)

		const tokenIds = await meemFacet
			.connect(signers[0])
			.tokenIdsOfOwner(signers[0].address)

		assert.equal(tokenIds[0].toNumber(), 1)

		const meem = await meemFacet.connect(signers[0]).getMeem(1)
		console.log({ meem, zero: meem[0] })
		assert.equal(meem.owner, signers[0].address)

		await assert.isRejected(
			erc721Facet.connect(signers[0]).transferFrom(signers[0].address, owner, 1)
		)
	})

	it('Can transfer child meem', async () => {
		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[0].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					0,
					contractAddress,
					0,
					contractAddress,
					0,
					meemMintData,
					meemMintData
				)
		).wait()
		assert.equal(status, 1)

		const totalSupply = await erc721Facet.connect(signers[0]).totalSupply()
		assert.equal(totalSupply.toNumber(), 3)

		const token0Owner = await erc721Facet.connect(signers[0]).ownerOf(1)
		assert.equal(token0Owner, signers[0].address)
		const ownerBalance = await erc721Facet
			.connect(signers[0])
			.balanceOf(signers[0].address)
		assert.equal(ownerBalance.toNumber(), 2)

		const tokenIds = await meemFacet
			.connect(signers[0])
			.tokenIdsOfOwner(signers[0].address)

		assert.equal(tokenIds[1].toNumber(), 2)

		const meem = await meemFacet.connect(signers[0]).getMeem(2)
		console.log({ meem, contractAddress })
		assert.equal(meem.owner, signers[0].address)
		assert.equal(meem.parent, contractAddress)
		assert.equal(meem.root, contractAddress)

		const ca = await erc721Facet.contractAddress()
		console.log({ contractAddress: ca })

		const transferResult = await (
			await erc721Facet
				.connect(signers[0])
				.transferFrom(signers[0].address, owner, 2)
		).wait()
		assert.equal(transferResult.status, 1)
	})

	it('Can transfer original meem', async () => {
		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[0].address,
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

		const totalSupply = await erc721Facet.connect(signers[0]).totalSupply()
		assert.equal(totalSupply.toNumber(), 4)

		const transferResult = await (
			await erc721Facet
				.connect(signers[0])
				.transferFrom(signers[0].address, owner, 3)
		).wait()
		assert.equal(transferResult.status, 1)
	})

	it('Can not mint meem w/ same external parent address', async () => {
		const otherAddress = '0xb822D949E8bE99bb137e04e548CF2fDc88513543'
		// First one can mint
		const { status } = await (
			await meemFacet
				.connect(signers[0])
				.mint(
					signers[0].address,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					0,
					otherAddress,
					1,
					otherAddress,
					1,
					meemMintData,
					meemMintData
				)
		).wait()
		assert.equal(status, 1)

		// Second one fails
		await assert.isRejected(
			meemFacet
				.connect(signers[0])
				.mint(
					owner,
					'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json',
					0,
					otherAddress,
					1,
					otherAddress,
					1,
					meemMintData,
					meemMintData
				)
		)
	})
})
