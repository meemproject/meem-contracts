// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import './ERC721TradableUpgradeable.sol';
import './MeemStandard.sol';
import './MeemPropsLibrary.sol';
import {AppStorage, LibAppStorage} from './LibAppStorage.sol';
import {LibERC721} from '../../shared/libraries/LibERC721.sol';

library LibMeem {
	using MeemPropsLibrary for MeemProperties;

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
		AppStorage storage s = LibAppStorage.diamondStorage();
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.addSplit(
			ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount,
			split
		);
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.updateSplitAt(
			ownerOf(tokenId),
			idx,
			s.nonOwnerSplitAllocationAmount,
			split
		);
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		AppStorage storage s = LibAppStorage.diamondStorage();

		if (propertyType == PropertyType.Meem) {
			// return _properties[tokenId];
			return s.meems[tokenId].properties;
		} else if (propertyType == PropertyType.Child) {
			// return _childProperties[tokenId];
			return s.meems[tokenId].childProperties;
		}

		revert('Invalid property type');
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.setProperties(mProperties);
		props.validateSplits(ownerOf(tokenId), s.nonOwnerSplitAllocationAmount);
	}

	function ownsToken(uint256 tokenId) internal view {
		// require(
		// 	ownerOf(tokenId) == msg.sender ||
		// 		hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
		// 	'Not owner of token'
		// );
		require(ownerOf(tokenId) == msg.sender, 'Not owner of token');
	}

	function ownerOf(uint256 _tokenId) internal view returns (address owner_) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		owner_ = s.meems[_tokenId].owner;
		require(owner_ != address(0), 'MeemFacet: invalid _tokenId');
	}

	function transfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();

		// remove
		uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
		uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
		if (index != lastIndex) {
			uint32 lastTokenId = s.ownerTokenIds[_from][lastIndex];
			s.ownerTokenIds[_from][index] = lastTokenId;
			s.ownerTokenIdIndexes[_from][lastTokenId] = index;
		}
		s.ownerTokenIds[_from].pop();
		delete s.ownerTokenIdIndexes[_from][_tokenId];
		if (s.approved[_tokenId] != address(0)) {
			delete s.approved[_tokenId];
			emit LibERC721.Approval(_from, address(0), _tokenId);
		}
		// add
		s.meems[_tokenId].owner = _to;
		s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
		s.ownerTokenIds[_to].push(uint32(_tokenId));
		emit LibERC721.Transfer(_from, _to, _tokenId);
	}
}
