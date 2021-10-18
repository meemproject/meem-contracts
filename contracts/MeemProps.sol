// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import './ERC721TradableUpgradeable.sol';
import './MeemStandard.sol';
import './MeemPropsLibrary.sol';

contract MeemProps is
	ERC721TradableUpgradeable,
	AccessControlUpgradeable,
	OwnableUpgradeable
{
	using MeemPropsLibrary for MeemProperties;

	uint256 internal _nonOwnerSplitAllocationAmount;
	mapping(uint256 => Chain) internal _chain;
	mapping(uint256 => address) internal _parent;
	mapping(uint256 => uint256) internal _parentTokenId;
	mapping(uint256 => MeemProperties) internal _properties;
	mapping(uint256 => MeemProperties) internal _childProperties;

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721Upgradeable, AccessControlUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) public {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.addPermission(permissionType, permission);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) public {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.removePermissionAt(permissionType, idx);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) public {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.updatePermissionAt(permissionType, idx, permission);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) public {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.addSplit(ownerOf(tokenId), _nonOwnerSplitAllocationAmount, split);
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) public {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.removeSplitAt(idx);
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) public {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.updateSplitAt(
			ownerOf(tokenId),
			idx,
			_nonOwnerSplitAllocationAmount,
			split
		);
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		if (propertyType == PropertyType.Meem) {
			return _properties[tokenId];
		} else if (propertyType == PropertyType.Child) {
			return _childProperties[tokenId];
		}

		revert('Invalid property type');
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.setProperties(mProperties);
		props.validateSplits(ownerOf(tokenId), _nonOwnerSplitAllocationAmount);
	}

	function ownsToken(uint256 tokenId) internal view {
		require(
			ownerOf(tokenId) == msg.sender ||
				hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
			'Not owner of token'
		);
	}
}
