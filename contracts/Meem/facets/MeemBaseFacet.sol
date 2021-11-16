// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemBaseStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemBaseFacet is IMeemBaseStandard {
	/** Mint a Meem */
	function mint(
		address to,
		string memory mTokenURI,
		Chain parentChain,
		address parent,
		uint256 parentTokenId,
		Chain rootChain,
		address root,
		uint256 rootTokenId,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties,
		PermissionType permissionType
	) public override {
		LibMeem.mint(
			to,
			mTokenURI,
			parentChain,
			parent,
			parentTokenId,
			rootChain,
			root,
			rootTokenId,
			mProperties,
			mChildProperties,
			permissionType
		);
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

	function ownedChildrenOf(uint256 tokenId, address owner)
		public
		view
		override
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.childrenOwnerTokens[tokenId][owner];
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

	function getMeem(uint256 tokenId) public view returns (Meem memory) {
		return LibMeem.getMeem(tokenId);
	}

	function childDepth() public view override returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.childDepth;
	}
}
