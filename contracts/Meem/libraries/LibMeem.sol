// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import '../interfaces/MeemStandard.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibPart} from '../../royalties/LibPart.sol';

library LibMeem {
	// Rarible royalties event
	event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

	// MeemStandard events
	event PermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);
	event SplitsSet(uint256 tokenId, Split[] splits);
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);
	event TotalChildrenSet(uint256 tokenId, int256 newTotalChildren);
	event TotalChildrenLocked(uint256 tokenId, address lockedBy);
	event ChildrenPerWalletSet(uint256 tokenId, int256 newTotalChildren);
	event ChildrenPerWalletLocked(uint256 tokenId, address lockedBy);

	function getRaribleV2Royalties(uint256 tokenId)
		internal
		view
		returns (LibPart.Part[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		uint256 numSplits = s.meems[tokenId].properties.splits.length;
		LibPart.Part[] memory parts = new LibPart.Part[](numSplits);
		for (
			uint256 i = 0;
			i < s.meems[tokenId].properties.splits.length;
			i++
		) {
			parts[i] = LibPart.Part({
				account: payable(
					s.meems[tokenId].properties.splits[i].toAddress
				),
				value: uint96(s.meems[tokenId].properties.splits[i].amount)
			});
		}

		return parts;
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		MeemPermission[] storage perms = getPermissions(props, permissionType);
		perms.push(permission);

		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		if (idx >= perms.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < perms.length - 1; i++) {
			perms[i] = perms[i + 1];
		}

		delete perms[perms.length - 1];
		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		perms[idx] = permission;
		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		require(props.splitsLockedBy == address(0), 'Splits are locked');
		props.splits.push(split);
		validateSplits(
			props,
			ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		require(props.splitsLockedBy == address(0), 'Splits are locked');
		require(
			props.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		if (idx >= props.splits.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < props.splits.length - 1; i++) {
			props.splits[i] = props.splits[i + 1];
		}

		delete props.splits[props.splits.length - 1];
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		require(props.splitsLockedBy == address(0), 'Splits are locked');
		require(
			props.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		props.splits[idx] = split;
		validateSplits(
			props,
			ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

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
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);

		for (uint256 i = 0; i < mProperties.copyPermissions.length; i++) {
			props.copyPermissions.push(mProperties.copyPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.remixPermissions.length; i++) {
			props.remixPermissions.push(mProperties.remixPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.readPermissions.length; i++) {
			props.readPermissions.push(mProperties.readPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.splits.length; i++) {
			props.splits.push(mProperties.splits[i]);
		}

		props.totalChildren = mProperties.totalChildren;
		props.totalChildrenLockedBy = mProperties.totalChildrenLockedBy;
		props.childrenPerWallet = mProperties.childrenPerWallet;
		props.childrenPerWalletLockedBy = mProperties.childrenPerWalletLockedBy;
		props.copyPermissionsLockedBy = mProperties.copyPermissionsLockedBy;
		props.remixPermissionsLockedBy = mProperties.remixPermissionsLockedBy;
		props.readPermissionsLockedBy = mProperties.readPermissionsLockedBy;
		props.splitsLockedBy = mProperties.splitsLockedBy;

		validateSplits(
			props,
			ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);

		emit PropertiesSet(tokenId, propertyType, props);
	}

	function requireOwnsToken(uint256 tokenId) internal view {
		// require(
		// 	ownerOf(tokenId) == msg.sender ||
		// 		hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
		// 	'Not owner of token'
		// );
		require(ownerOf(tokenId) == msg.sender, 'Not owner of token');
	}

	function permissionNotLocked(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view {
		if (permissionType == PermissionType.Copy) {
			require(
				self.copyPermissionsLockedBy == address(0),
				'Copy permissions are locked'
			);
		} else if (permissionType == PermissionType.Remix) {
			require(
				self.remixPermissionsLockedBy == address(0),
				'Remix permissions are locked'
			);
		} else if (permissionType == PermissionType.Read) {
			require(
				self.readPermissionsLockedBy == address(0),
				'Read permissions are locked'
			);
		}
	}

	function ownerOf(uint256 _tokenId) internal view returns (address owner_) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		owner_ = s.meems[_tokenId].owner;
		require(owner_ != address(0), 'LibMeem: invalid _tokenId');
	}

	function validateSplits(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) internal view {
		// Ensure addresses are unique
		for (uint256 i = 0; i < self.splits.length; i++) {
			address split1 = self.splits[i].toAddress;

			for (uint256 j = 0; j < self.splits.length; j++) {
				address split2 = self.splits[j].toAddress;
				if (i != j && split1 == split2) {
					revert('Split addresses must be unique');
				}
			}
		}

		uint256 totalAmount = 0;
		uint256 totalAmountOfNonOwner = 0;
		// Require that split amounts
		for (uint256 i = 0; i < self.splits.length; i++) {
			totalAmount += self.splits[i].amount;
			if (self.splits[i].toAddress != tokenOwner) {
				totalAmountOfNonOwner += self.splits[i].amount;
			}
		}

		require(
			totalAmount <= 10000,
			'Total basis points amount must be less than 10000 (100%)'
		);

		require(
			totalAmountOfNonOwner >= nonOwnerSplitAllocationAmount,
			'Split allocation for non-owner is too low'
		);
	}

	function getPermissions(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view returns (MeemPermission[] storage) {
		if (permissionType == PermissionType.Copy) {
			require(
				self.copyPermissionsLockedBy == address(0),
				'Copy permissions are locked'
			);
			return self.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			require(
				self.remixPermissionsLockedBy == address(0),
				'Remix permissions are locked'
			);
			return self.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			require(
				self.readPermissionsLockedBy == address(0),
				'Read permissions are locked'
			);
			return self.readPermissions;
		}

		revert('Invalid permission type');
	}

	function transfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		// remove
		uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
		uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
		if (index != lastIndex) {
			uint256 lastTokenId = s.ownerTokenIds[_from][lastIndex];
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
		s.ownerTokenIds[_to].push(_tokenId);
		emit LibERC721.Transfer(_from, _to, _tokenId);
	}

	function setTotalChildren(uint256 tokenId, int256 newTotalChildren)
		internal
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);

		if (newTotalChildren > -1) {
			require(
				uint256(newTotalChildren) <= s.children[tokenId].length,
				'Total copies can not be less than the the existing number of copies'
			);
		}

		require(
			s.meems[tokenId].properties.totalChildrenLockedBy == address(0),
			'Total Children is locked'
		);

		s.meems[tokenId].properties.totalChildren = newTotalChildren;
		emit TotalChildrenSet(tokenId, newTotalChildren);
	}

	function lockTotalChildren(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);

		require(
			s.meems[tokenId].properties.totalChildrenLockedBy == address(0),
			'Total Children is already locked'
		);

		s.meems[tokenId].properties.totalChildrenLockedBy = msg.sender;
		emit TotalChildrenLocked(tokenId, msg.sender);
	}

	function setChildrenPerWallet(uint256 tokenId, int256 newTotalChildren)
		internal
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);

		if (newTotalChildren > -1) {
			require(
				uint256(newTotalChildren) <= s.children[tokenId].length,
				'Total children can not be less than the the existing number of copies'
			);
		}

		require(
			s.meems[tokenId].properties.childrenPerWalletLockedBy == address(0),
			'Total Children is locked'
		);

		s.meems[tokenId].properties.childrenPerWallet = newTotalChildren;
		emit ChildrenPerWalletSet(tokenId, newTotalChildren);
	}

	function lockChildrenPerWallet(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);

		require(
			s.meems[tokenId].properties.childrenPerWalletLockedBy == address(0),
			'Children per wallet is already locked'
		);

		s.meems[tokenId].properties.childrenPerWalletLockedBy = msg.sender;
		emit ChildrenPerWalletLocked(tokenId, msg.sender);
	}
}
