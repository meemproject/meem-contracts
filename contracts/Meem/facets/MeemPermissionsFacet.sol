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
	function setTotalChildren(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalChildren
	) external override {
		LibMeem.setTotalChildren(tokenId, propertyType, newTotalChildren);
	}

	function lockTotalChildren(uint256 tokenId, PropertyType propertyType)
		external
		override
	{
		LibMeem.lockTotalChildren(tokenId, propertyType);
	}

	function setChildrenPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalChildren
	) external override {
		LibMeem.setChildrenPerWallet(tokenId, propertyType, newTotalChildren);
	}

	function lockChildrenPerWallet(uint256 tokenId, PropertyType propertyType)
		external
		override
	{
		LibMeem.lockChildrenPerWallet(tokenId, propertyType);
	}

	function lockPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType
	) external override {
		LibMeem.lockPermissions(tokenId, propertyType, permissionType);
	}

	function setPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] memory permissions
	) external override {
		LibMeem.setPermissions(
			tokenId,
			propertyType,
			permissionType,
			permissions
		);
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) external override {
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
	) external override {
		LibMeem.removePermissionAt(tokenId, propertyType, permissionType, idx);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) external override {
		LibMeem.updatePermissionAt(
			tokenId,
			propertyType,
			permissionType,
			idx,
			permission
		);
	}
}
