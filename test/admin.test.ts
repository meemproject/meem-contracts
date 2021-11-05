import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers } from 'hardhat'
import { deployDiamond } from '../tasks'
import { AccessControlFacet, MeemAdminFacet, Ownable } from '../typechain'

chai.use(chaiAsPromised)

describe('Contract Admin', function Test() {
	let adminFacet: MeemAdminFacet
	let ownershipFacet: Ownable
	let accessControlFacet: AccessControlFacet
	let signers: SignerWithAddress[]
	const someUser = '0xde19C037a85A609ec33Fc747bE9Db8809175C3a5'

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers
		})

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

		const splitAmount = await adminFacet
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
})
