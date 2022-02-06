import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { MeemAdminFacet, MeemBaseFacet, MeemQueryFacet } from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, Permission } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Minting Permissions', function Test() {
	let meemFacet: MeemBaseFacet
	let meemAdminFacet: MeemAdminFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]
	let contractAddress: string
	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
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
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)
	}

	it('Mints can not exceed childDepth', async () => {
		await mintZeroMeem()

		await (await meemAdminFacet.setChildDepth(1)).wait()

		const { status } = await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		const m1 = await queryFacet.getMeem(token1)
		assert.equal(m1.generation.toNumber(), 1)

		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token1,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Increases child depth and generation is updated properly', async () => {
		await mintZeroMeem()
		await (await meemAdminFacet.setChildDepth(2)).wait()

		// First gen
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		// Second gen
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token1,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		const m2 = await queryFacet.getMeem(token2)
		assert.equal(m2.generation.toNumber(), 2)

		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token2,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Respects total remixes', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				{ ...meemMintData, totalRemixes: 1 },
				meemMintData
			)
		).wait()

		// Succeeds as first child
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				{ ...meemMintData, totalRemixes: 1 },
				meemMintData
			)
		).wait()

		// Fails as second child
		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				{ ...meemMintData, totalRemixes: 1 },
				meemMintData
			)
		)
	})

	it('Respects children per wallet', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				{ ...meemMintData, remixesPerWallet: 1 },
				meemMintData
			)
		).wait()

		// Succeeds as first child
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		// Fails as second child per wallet
		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: signers[1].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)

		// Succeeds as different owner
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[2].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()
	})

	it('Respects owner only minting', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				{
					...meemMintData,
					copyPermissions: [
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: []
						}
					]
				},
				meemMintData
			)
		).wait()

		// Succeeds as owner
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		// Fails as non-owner
		await assert.isRejected(
			meemFacet.connect(signers[1]).mint(
				{
					to: signers[1].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Respects address only minting', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[0].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address]
						}
					]
				},
				meemMintData
			)
		).wait()

		// Succeeds as approved address
		await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[1].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		// Fails as owner
		await assert.isRejected(
			meemFacet.connect(signers[0]).mint(
				{
					to: owner,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)

		// Fails as other address
		await assert.isRejected(
			meemFacet.connect(signers[3]).mint(
				{
					to: signers[3].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)
	})

	it('Allows multiple permissions', async () => {
		await (
			await meemFacet.connect(signers[0]).mint(
				{
					to: signers[2].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isVerified: true,
					mintedBy: signers[0].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Addresses,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: [signers[1].address]
						},
						{
							permission: Permission.Owner,
							numTokens: 0,
							lockedBy: zeroAddress,
							addresses: []
						}
					]
				},
				meemMintData
			)
		).wait()

		// Succeeds as approved address
		await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[1].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		// Succeeds as owner
		await (
			await meemFacet.connect(signers[2]).mint(
				{
					to: signers[2].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		).wait()

		// Fails as other address
		await assert.isRejected(
			meemFacet.connect(signers[3]).mint(
				{
					to: signers[3].address,
					mTokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isVerified: false,
					mintedBy: signers[0].address
				},
				meemMintData,
				meemMintData
			)
		)
	})
})
