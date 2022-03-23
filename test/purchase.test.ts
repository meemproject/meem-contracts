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
	MeemPermissionsFacet,
	MeemQueryFacet
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, Permission, UriSource } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Purchasing', function Test() {
	let meemFacet: MeemBaseFacet
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

		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			contractAddress
		)) as MeemQueryFacet
	})

	it('Can require cost to mint', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: token0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					reactionTypes: [],
					uriSource: UriSource.TokenUri,
					mintedBy: signers[0].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[1].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(
			meemFacet.connect(signers[2]).mint(
				{
					to: signers[2].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					reactionTypes: [],
					uriSource: UriSource.TokenUri,
					mintedBy: signers[2].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[2].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData
			)
		)
	})

	it('Can pay required cost to mint', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: token0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					reactionTypes: [],
					uriSource: UriSource.TokenUri,
					mintedBy: signers[0].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[1].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		await (
			await meemFacet.connect(signers[2]).mint(
				{
					to: signers[2].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					reactionTypes: [],
					uriSource: UriSource.TokenUri,
					mintedBy: signers[2].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[2].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData,
				{
					value: ethers.utils.parseEther('0.1')
				}
			)
		).wait()
	})

	it('Can not pay less than required cost to mint', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: token0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					reactionTypes: [],
					uriSource: UriSource.TokenUri,
					mintedBy: signers[0].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[1].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		await assert.isRejected(
			meemFacet.connect(signers[2]).mint(
				{
					to: signers[2].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: contractAddress,
					parentTokenId: token0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					reactionTypes: [],
					uriSource: UriSource.TokenUri,
					mintedBy: signers[2].address
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[2].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData,
				{
					value: ethers.utils.parseEther('0.099')
				}
			)
		)
	})

	it('Can mint and remix with cost', async () => {
		const { status } = await (
			await meemFacet.connect(signers[0]).mintAndRemix(
				{
					to: signers[1].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					uriSource: UriSource.TokenUri,
					mintedBy: signers[1].address,
					reactionTypes: []
				},
				{
					...meemMintData,
					remixPermissions: [
						{
							permission: Permission.Anyone,
							numTokens: 0,
							lockedBy: signers[2].address,
							addresses: [],
							costWei: ethers.utils.parseEther('0.1')
						}
					]
				},
				meemMintData,
				{
					to: signers[2].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Remix,
					data: '',
					isURILocked: false,
					uriSource: UriSource.TokenUri,
					mintedBy: signers[1].address,
					reactionTypes: []
				},
				meemMintData,
				meemMintData,
				{
					value: ethers.utils.parseEther('0.1')
				}
			)
		).wait()
		assert.equal(status, 1)
	})
})
