// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import './MeemStandard.sol';

// library MeemPermissionLibrary {
// 	function removePermissionAtIndex(MeemPermission[] storage self, uint256 idx)
// 		public
// 	{
// 		if (idx >= self.length) {
// 			revert('Index out of range');
// 		}

// 		for (uint256 i = idx; i < self.length - 1; i++) {
// 			self[i] = self[i + 1];
// 		}

// 		delete self[self.length - 1];
// 	}
// }

library MeemPropsLibrary {
	function properties(MeemProperties storage self)
		public
		pure
		returns (MeemProperties memory)
	{
		return self;
	}

	function addPermission(
		MeemProperties storage self,
		PermissionType permissionType,
		MeemPermission memory permission
	) public {
		MeemPermission[] storage perms = getPermissions(self, permissionType);

		perms.push(permission);
	}

	function updatePermissionAt(
		MeemProperties storage self,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) public {
		permissionNotLocked(self, permissionType);

		MeemPermission[] storage perms = getPermissions(self, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		perms[idx] = permission;
	}

	function removePermissionAt(
		MeemProperties storage self,
		PermissionType permissionType,
		uint256 idx
	) public {
		permissionNotLocked(self, permissionType);

		MeemPermission[] storage perms = getPermissions(self, permissionType);
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
	}

	function addSplit(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount,
		Split memory split
	) public {
		require(self.splitsLockedBy == address(0), 'Splits are locked');
		self.splits.push(split);
		validateSplits(self, tokenOwner, nonOwnerSplitAllocationAmount);
	}

	function removeSplitAt(MeemProperties storage self, uint256 idx) public {
		require(self.splitsLockedBy == address(0), 'Splits are locked');
		require(
			self.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		if (idx >= self.splits.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < self.splits.length - 1; i++) {
			self.splits[i] = self.splits[i + 1];
		}

		delete self.splits[self.splits.length - 1];
	}

	function updateSplitAt(
		MeemProperties storage self,
		address tokenOwner,
		uint256 idx,
		uint256 nonOwnerSplitAllocationAmount,
		Split memory split
	) public {
		require(self.splitsLockedBy == address(0), 'Splits are locked');
		require(
			self.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		self.splits[idx] = split;
		validateSplits(self, tokenOwner, nonOwnerSplitAllocationAmount);
	}

	function validateSplits(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) public view {
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
	) public view returns (MeemPermission[] storage) {
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

	function permissionNotLocked(
		MeemProperties storage self,
		PermissionType permissionType
	) public view {
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

	function setProperties(
		MeemProperties storage self,
		MeemProperties memory mProperties
	) public {
		for (uint256 i = 0; i < mProperties.copyPermissions.length; i++) {
			self.copyPermissions.push(mProperties.copyPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.remixPermissions.length; i++) {
			self.remixPermissions.push(mProperties.remixPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.readPermissions.length; i++) {
			self.readPermissions.push(mProperties.readPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.splits.length; i++) {
			self.splits.push(mProperties.splits[i]);
		}

		self.totalCopies = mProperties.totalCopies;
		self.totalCopiesLockedBy = mProperties.totalCopiesLockedBy;
		self.copyPermissionsLockedBy = mProperties.copyPermissionsLockedBy;
		self.remixPermissionsLockedBy = mProperties.remixPermissionsLockedBy;
		self.readPermissionsLockedBy = mProperties.readPermissionsLockedBy;
		self.splitsLockedBy = mProperties.splitsLockedBy;
	}
}
