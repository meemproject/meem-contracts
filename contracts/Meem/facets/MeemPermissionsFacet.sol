// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemPermissionsStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemPermissionsFacet is IMeemPermissionsStandard {
	function setTotalChildren(uint256 tokenId, int256 newTotalChildren)
		public
		override
	{
		LibMeem.setTotalChildren(tokenId, newTotalChildren);
	}

	function lockTotalChildren(uint256 tokenId) public override {
		LibMeem.lockTotalChildren(tokenId);
	}

	function setChildrenPerWallet(uint256 tokenId, int256 newTotalChildren)
		public
		override
	{
		LibMeem.setChildrenPerWallet(tokenId, newTotalChildren);
	}

	function lockChildrenPerWallet(uint256 tokenId) public override {
		LibMeem.lockChildrenPerWallet(tokenId);
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) public override {
		LibMeem.addPermission(
			tokenId,
			propertyType,
			permissionType,
			permission
		);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) public override {
		LibMeem.removePermissionAt(tokenId, propertyType, permissionType, idx);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) public override {
		LibMeem.updatePermissionAt(
			tokenId,
			propertyType,
			permissionType,
			idx,
			permission
		);
	}
}