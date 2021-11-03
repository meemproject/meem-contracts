import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, upgrades } from 'hardhat'
import { deployDiamond } from '../tasks'
import { AccessControlFacet, MeemSplitsFacet, Ownable } from '../typechain'

chai.use(chaiAsPromised)

describe('Contract Admin', function Test() {
	let meemFacet: MeemSplitsFacet
	let ownershipFacet: Ownable
	let accessControlFacet: AccessControlFacet
	let signers: SignerWithAddress[]

	before(async () => {
		signers = await ethers.getSigners()
		console.log({ signers })
		const { DiamondProxy: DiamondAddress } = await deployDiamond({
			ethers,
			upgrades
		})

		meemFacet = (await ethers.getContractAt(
			'MeemSplitsFacet',
			DiamondAddress
		)) as MeemSplitsFacet

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
		const adminRole = await accessControlFacet.DEFAULT_ADMIN_ROLE()
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
			await meemFacet.connect(signers[0]).setNonOwnerSplitAllocationAmount(100)
		).wait()
		assert.equal(status, 1)

		const splitAmount = await meemFacet
			.connect(signers[0])
			.nonOwnerSplitAllocationAmount()
		assert.equal(splitAmount.toNumber(), 100)
	})

	it('Can not set split amount as non-admin', async () => {
		await assert.isRejected(
			meemFacet.connect(signers[1]).setNonOwnerSplitAllocationAmount(100)
		)
	})
})
