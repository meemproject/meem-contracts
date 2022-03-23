import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import {
	AccessControlFacet,
	MeemAdminFacet,
	MeemBaseFacet,
	MeemQueryFacet,
	MeemSplitsFacet,
	Ownable
} from '../typechain'
import { meemMintData } from './helpers/meemProperties'
import { Chain, MeemType, UriSource } from './helpers/meemStandard'
import { zeroAddress } from './helpers/utils'

chai.use(chaiAsPromised)

describe('Contract Admin', function Test() {
	let meemFacet: MeemBaseFacet
	let adminFacet: MeemAdminFacet
	let meemSplitsFacet: MeemSplitsFacet
	let ownershipFacet: Ownable
	let accessControlFacet: AccessControlFacet
	let queryFacet: MeemQueryFacet
	let signers: SignerWithAddress[]
	const someUser = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const ipfsURL = 'ipfs://QmWEFSMku6yGLQ9TQr66HjSd9kay8ZDYKbBEfjNi4pLtrr/1'
	const owner = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'
	const parent = '0xc4A383d1Fd38EDe98F032759CE7Ed8f3F10c82B0'
	const token0 = 100000

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers
		})

		meemFacet = (await ethers.getContractAt(
			'MeemBaseFacet',
			DiamondAddress
		)) as MeemBaseFacet

		meemSplitsFacet = (await ethers.getContractAt(
			'MeemSplitsFacet',
			DiamondAddress
		)) as MeemSplitsFacet

		adminFacet = (await ethers.getContractAt(
			'MeemAdminFacet',
			DiamondAddress
		)) as MeemAdminFacet

		ownershipFacet = (await ethers.getContractAt(
			'@solidstate/contracts/access/Ownable.sol:Ownable',
			DiamondAddress
		)) as Ownable

		accessControlFacet = (await ethers.getContractAt(
			'AccessControlFacet',
			DiamondAddress
		)) as AccessControlFacet

		queryFacet = (await ethers.getContractAt(
			'MeemQueryFacet',
			DiamondAddress
		)) as MeemQueryFacet
	})

	it('Assigns ownership to deployer', async () => {
		const o = await ownershipFacet.owner()
		assert.equal(o, signers[0].address)
	})

	it('Assigns roles to deployer', async () => {
		const adminRole = await accessControlFacet.ADMIN_ROLE()
		const hasAdminRole = await accessControlFacet.hasRole(
			signers[0].address,
			adminRole
		)
		assert.isTrue(hasAdminRole)
		const minterRole = await accessControlFacet.MINTER_ROLE()
		const hasMinterRole = await accessControlFacet.hasRole(
			signers[0].address,
			minterRole
		)
		assert.isTrue(hasMinterRole)
	})

	it('Can set split amount as admin', async () => {
		const { status } = await (
			await adminFacet.connect(signers[0]).setNonOwnerSplitAllocationAmount(100)
		).wait()
		assert.equal(status, 1)

		const splitAmount = await meemSplitsFacet
			.connect(signers[0])
			.nonOwnerSplitAllocationAmount()
		assert.equal(splitAmount.toNumber(), 100)
	})

	it('Can not set split amount as non-admin', async () => {
		await assert.isRejected(
			adminFacet.connect(signers[1]).setNonOwnerSplitAllocationAmount(100)
		)
	})

	it('Can grant role as admin', async () => {
		const minterRole = await accessControlFacet.MINTER_ROLE()
		await accessControlFacet.connect(signers[0]).grantRole(someUser, minterRole)

		const hasRole = await accessControlFacet
			.connect(signers[0])
			.hasRole(someUser, minterRole)
		assert.isTrue(hasRole)
	})

	it('Can revoke role as admin', async () => {
		const minterRole = await accessControlFacet.MINTER_ROLE()
		await accessControlFacet
			.connect(signers[0])
			.revokeRole(someUser, minterRole)

		const hasRole = await accessControlFacet
			.connect(signers[0])
			.hasRole(someUser, minterRole)
		assert.isFalse(hasRole)
	})

	it('Can not grant role as non-admin', async () => {
		const minterRole = await accessControlFacet.MINTER_ROLE()
		await assert.isRejected(
			accessControlFacet.connect(signers[1]).grantRole(someUser, minterRole)
		)
	})

	it('Can not revoke role as non-admin', async () => {
		const minterRole = await accessControlFacet.MINTER_ROLE()
		await assert.isRejected(
			accessControlFacet.connect(signers[1]).revokeRole(someUser, minterRole)
		)
	})

	it('Can not set root as non-admin', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		const token = await queryFacet.getMeem(token0)
		assert.equal(token.root, zeroAddress)
		assert.equal(token.rootTokenId.toNumber(), 0)

		await assert.isRejected(
			adminFacet
				.connect(signers[1])
				.setTokenRoot(token0, Chain.Ethereum, parent, 23)
		)
	})

	it('Can set root as admin', async () => {
		const { status } = await (
			await meemFacet.connect(signers[1]).mint(
				{
					to: signers[4].address,
					tokenURI: ipfsURL,
					parentChain: Chain.Polygon,
					parent: zeroAddress,
					parentTokenId: 0,
					meemType: MeemType.Original,
					data: '',
					isURILocked: false,
					mintedBy: signers[0].address,
					reactionTypes: [],
					uriSource: UriSource.TokenUri
				},
				meemMintData,
				meemMintData
			)
		).wait()
		assert.equal(status, 1)

		let token = await queryFacet.getMeem(token0)
		assert.equal(token.root, zeroAddress)
		assert.equal(token.rootTokenId.toNumber(), 0)

		await adminFacet
			.connect(signers[0])
			.setTokenRoot(token0, Chain.Ethereum, parent, 23)

		token = await queryFacet.getMeem(token0)
		assert.equal(token.root, parent)
		assert.equal(token.rootChain, Chain.Ethereum)
		assert.equal(token.rootTokenId.toNumber(), 23)
	})
})
