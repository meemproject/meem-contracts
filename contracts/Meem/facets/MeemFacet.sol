// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibStrings} from '../libraries/LibStrings.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {AppStorage} from '../libraries/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split} from '../interfaces/MeemStandard.sol';

contract MeemFacet {
	AppStorage internal s;

	/** Mint a Meem */
	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties
	) public {
		LibAccessControl.requireRole(s.MINTER_ROLE);
		uint256 tokenId = s.tokenCounter;
		LibERC721._safeMint(to, tokenId);
		s.tokenURIs[tokenId] = mTokenURI;

		// Initializes mapping w/ default values
		delete s.meems[tokenId];

		s.meems[tokenId].chain = chain;
		s.meems[tokenId].parent = parent;
		s.meems[tokenId].parentTokenId = parentTokenId;
		s.meems[tokenId].owner = to;

		LibMeem.setProperties(tokenId, PropertyType.Meem, mProperties);
		LibMeem.setProperties(tokenId, PropertyType.Child, mChildProperties);

		// Keep track of children Meems
		if (parent == address(this)) {
			s.children[parentTokenId].push(tokenId);
		}

		s.tokenCounter += 1;
	}

	function setNonOnwerSplitAllocationAmount(uint256 amount) public {
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		if (amount < 0 || amount > 10000) {
			revert('Amount must be between 0 - 10000 basis points');
		}

		s.nonOwnerSplitAllocationAmount = amount;
	}

	function nonOwnerSplitAllocationAmount() public view returns (uint256) {
		return s.nonOwnerSplitAllocationAmount;
	}

	function childrenOf(uint256 tokenId)
		public
		view
		returns (uint256[] memory)
	{
		return s.children[tokenId];
	}

	function numChildrenOf(uint256 tokenId) public view returns (uint256) {
		return s.children[tokenId].length;
	}

	function setTotalCopies(uint256 tokenId, uint256 newTotalCopies) public {
		LibMeem.requireOwnsToken(tokenId);

		require(
			newTotalCopies <= numChildrenOf(tokenId),
			'Total copies can not be less than the the existing number of copies'
		);

		require(
			s.meems[tokenId].properties.totalCopiesLockedBy == address(0),
			'Total Copies is locked'
		);

		s.meems[tokenId].properties.totalCopies = newTotalCopies;
	}

	function lockTotalCopies(uint256 tokenId) public {
		LibMeem.requireOwnsToken(tokenId);

		require(
			s.meems[tokenId].properties.totalCopiesLockedBy == address(0),
			'Total Copies is already locked'
		);

		s.meems[tokenId].properties.totalCopiesLockedBy = msg.sender;
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) public {
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
	) public {
		LibMeem.removePermissionAt(tokenId, propertyType, permissionType, idx);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) public {
		LibMeem.updatePermissionAt(
			tokenId,
			propertyType,
			permissionType,
			idx,
			permission
		);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) public {
		LibMeem.addSplit(tokenId, propertyType, split);
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) public {
		LibMeem.removeSplitAt(tokenId, propertyType, idx);
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) public {
		LibMeem.updateSplitAt(tokenId, propertyType, idx, split);
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		return LibMeem.getProperties(tokenId, propertyType);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		LibMeem.setProperties(tokenId, propertyType, mProperties);
	}

	function setTokenCounter(uint256 tokenCounter) public {
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		s.tokenCounter = tokenCounter;
	}
}
