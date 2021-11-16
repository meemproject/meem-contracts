// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem, WrappedItem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemBaseStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemQueryFacet {
	function tokenIdsOfOwner(address _owner)
		public
		view
		returns (uint256[] memory tokenIds_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ownerTokenIds[_owner];
	}

	function isNFTWrapped(
		Chain chain,
		address contractAddress,
		uint256 tokenId
	) public view returns (bool) {
		return LibMeem.isNFTWrapped(chain, contractAddress, tokenId);
	}

	function isWrapped(WrappedItem[] memory items)
		public
		view
		returns (uint256[] memory)
	{
		return LibMeem.wrappedTokens(items);
	}
}
