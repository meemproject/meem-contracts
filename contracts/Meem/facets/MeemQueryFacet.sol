// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem, WrappedItem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemQueryStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemQueryFacet is IMeemQueryStandard {
	function childrenOf(uint256 tokenId)
		external
		view
		override
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.children[tokenId];
	}

	function ownedChildrenOf(uint256 tokenId, address owner)
		external
		view
		override
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.childrenOwnerTokens[tokenId][owner];
	}

	function numChildrenOf(uint256 tokenId)
		external
		view
		override
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.children[tokenId].length;
	}

	function getMeem(uint256 tokenId)
		external
		view
		override
		returns (Meem memory)
	{
		return LibMeem.getMeem(tokenId);
	}

	function childDepth() external view override returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.childDepth;
	}

	function tokenIdsOfOwner(address _owner)
		external
		view
		override
		returns (uint256[] memory tokenIds_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ownerTokenIds[_owner];
	}

	function tokenIdOfOwnerIndex(address _owner, uint256 tokenId)
		external
		view
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ownerTokenIdIndexes[_owner][tokenId];
	}

	function isNFTWrapped(
		Chain chain,
		address contractAddress,
		uint256 tokenId
	) external view override returns (bool) {
		return LibMeem.isNFTWrapped(chain, contractAddress, tokenId);
	}

	function wrappedTokens(WrappedItem[] memory items)
		external
		view
		override
		returns (uint256[] memory)
	{
		return LibMeem.wrappedTokens(items);
	}
}
