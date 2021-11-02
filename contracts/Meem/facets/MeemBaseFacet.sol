// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibStrings} from '../libraries/LibStrings.sol';
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

	function tokenIdsOfOwner(address _owner)
		public
		view
		returns (uint256[] memory tokenIds_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ownerTokenIds[_owner];
	}
}
