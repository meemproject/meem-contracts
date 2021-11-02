// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibStrings} from '../libraries/LibStrings.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {RoyaltiesV2} from '../../royalties/RoyaltiesV2.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemFacet is RoyaltiesV2, IMeemStandard {
	function getRaribleV2Royalties(uint256 tokenId)
		public
		view
		override
		returns (LibPart.Part[] memory)
	{
		return LibMeem.getRaribleV2Royalties(tokenId);
	}

	/** Mint a Meem */
	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		address root,
		uint256 rootTokenId,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties
	) public override returns (uint256 tokenId_) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.MINTER_ROLE);
		LibMeem.requireValidMeem(parent, parentTokenId);
		uint256 tokenId = s.tokenCounter;
		LibERC721._safeMint(to, tokenId);
		s.tokenURIs[tokenId] = mTokenURI;

		// Initializes mapping w/ default values
		delete s.meems[tokenId];

		s.meems[tokenId].chain = chain;
		s.meems[tokenId].parent = parent;
		s.meems[tokenId].parentTokenId = parentTokenId;
		s.meems[tokenId].root = root;
		s.meems[tokenId].rootTokenId = rootTokenId;
		s.meems[tokenId].owner = to;

		LibMeem.setProperties(tokenId, PropertyType.Meem, mProperties);
		LibMeem.setProperties(tokenId, PropertyType.Child, mChildProperties);

		// Keep track of children Meems
		if (parent == address(this)) {
			s.children[parentTokenId].push(tokenId);
		} else {
			s.wrappedNFTs[parent][parentTokenId] = true;
		}

		if (root == address(this)) {
			s.decendants[rootTokenId].push(tokenId);
		}

		s.tokenCounter += 1;

		require(
			LibERC721._checkOnERC721Received(address(0), to, tokenId, ''),
			'ERC721: transfer to non ERC721Receiver implementer'
		);

		emit LibERC721.Transfer(address(0), to, tokenId);
		return tokenId;
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

	function childrenOf(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.children[tokenId];
	}

	function numChildrenOf(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.children[tokenId].length;
	}

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

	// function setContractURI(string memory newContractURI) public {
	// 	LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
	// 	LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
	// 	s.contractURI = newContractURI;
	// }

	function getMeem(uint256 tokenId) public view returns (Meem memory) {
		return LibMeem.getMeem(tokenId);
	}

	function setTokenCounter(uint256 tokenCounter) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		s.tokenCounter = tokenCounter;
	}

	function childDepth() public view override returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.childDepth;
	}

	function setChildDepth(uint256 newChildDepth) public override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		s.childDepth = newChildDepth;
	}

	// function tokenIdsOfOwner(address _owner)
	// 	public
	// 	view
	// 	returns (uint256[] memory tokenIds_)
	// {
	// 	LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
	// 	return s.ownerTokenIds[_owner];
	// }

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
}
