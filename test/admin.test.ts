import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai, { assert } from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { ethers, upgrades } from 'hardhat'
import { deployDiamond } from '../tasks'
import { MeemSplitsFacet } from '../typechain'

chai.use(chaiAsPromised)

describe('Contract Admin', function Test() {
	let meemFacet: MeemSplitsFacet
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
