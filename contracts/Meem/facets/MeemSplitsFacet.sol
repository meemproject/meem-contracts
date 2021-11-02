// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibStrings} from '../libraries/LibStrings.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemSplitsStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {RoyaltiesV2} from '../../royalties/RoyaltiesV2.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemSplitsFacet is RoyaltiesV2, IMeemSplitsStandard {
	function getRaribleV2Royalties(uint256 tokenId)
		public
		view
		override
		returns (LibPart.Part[] memory)
	{
		return LibMeem.getRaribleV2Royalties(tokenId);
	}

	function setNonOwnerSplitAllocationAmount(uint256 amount) public override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		if (amount < 0 || amount > 10000) {
			revert('Amount must be between 0 - 10000 basis points');
		}

		s.nonOwnerSplitAllocationAmount = amount;
	}

	function nonOwnerSplitAllocationAmount()
		public
		view
		override
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.nonOwnerSplitAllocationAmount;
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) public override {
		LibMeem.addSplit(tokenId, propertyType, split);
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) public override {
		LibMeem.removeSplitAt(tokenId, propertyType, idx);
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) public override {
		LibMeem.updateSplitAt(tokenId, propertyType, idx, split);
	}
}
