// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibStrings} from '../libraries/LibStrings.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {AppStorage} from '../libraries/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {RoyaltiesV2} from '../../royalties/RoyaltiesV2.sol';
import {LibPart} from '../../royalties/LibPart.sol';
import {MeemStandard} from '../interfaces/MeemStandard.sol';

contract MeemFacet is RoyaltiesV2, MeemStandard {
	AppStorage internal s;

	function getRaribleV2Royalties(uint256 tokenId)
		public
		view
		override
		returns (LibPart.Part[] memory)
	{}

	/** Mint a Meem */
	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties
	) public override {
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

	function setNonOwnerSplitAllocationAmount(uint256 amount) public override {
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
		return s.nonOwnerSplitAllocationAmount;
	}

	function childrenOf(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		return s.children[tokenId];
	}

	function numChildrenOf(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		return s.children[tokenId].length;
	}

	function setTotalChildren(uint256 tokenId, uint256 newTotalChildren)
		public
		override
	{
		LibMeem.requireOwnsToken(tokenId);

		require(
			newTotalChildren <= numChildrenOf(tokenId),
			'Total copies can not be less than the the existing number of copies'
		);

		require(
			s.meems[tokenId].properties.totalChildrenLockedBy == address(0),
			'Total Children is locked'
		);

		s.meems[tokenId].properties.totalChildren = newTotalChildren;
	}

	function lockTotalChildren(uint256 tokenId) public override {
		LibMeem.requireOwnsToken(tokenId);

		require(
			s.meems[tokenId].properties.totalChildrenLockedBy == address(0),
			'Total Children is already locked'
		);

		s.meems[tokenId].properties.totalChildrenLockedBy = msg.sender;
	}

	function setChildrenPerWallet(uint256 tokenId, uint256 newTotalChildren)
		public
		override
	{
		LibMeem.requireOwnsToken(tokenId);

		require(
			newTotalChildren <= numChildrenOf(tokenId),
			'Total children can not be less than the the existing number of copies'
		);

		require(
			s.meems[tokenId].properties.childrenPerWalletLockedBy == address(0),
			'Total Children is locked'
		);

		s.meems[tokenId].properties.childrenPerWallet = newTotalChildren;
	}

	function lockChildrenPerWallet(uint256 tokenId) public override {
		LibMeem.requireOwnsToken(tokenId);

		require(
			s.meems[tokenId].properties.childrenPerWalletLockedBy == address(0),
			'Children per wallet is already locked'
		);

		s.meems[tokenId].properties.childrenPerWalletLockedBy = msg.sender;
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
