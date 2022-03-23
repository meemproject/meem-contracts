// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemBaseStandard, MeemMintParameters, MeemType} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemBaseFacet is IMeemBaseStandard {
	/** Mint a Meem */
	function mint(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external payable override {
		LibMeem.mint(params, properties, childProperties);
	}

	function mintAndCopy(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		address toCopyAddress
	) external payable override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.MINTER_ROLE);
		uint256 tokenId = LibMeem.mint(params, properties, childProperties);

		LibMeem.mint(
			MeemMintParameters({
				to: toCopyAddress,
				tokenURI: params.tokenURI,
				parentChain: params.parentChain,
				parent: address(this),
				parentTokenId: tokenId,
				meemType: MeemType.Copy,
				data: params.data,
				isURILocked: params.isURILocked,
				mintedBy: params.mintedBy,
				uriSource: params.uriSource,
				reactionTypes: params.reactionTypes
			}),
			properties,
			childProperties
		);
	}

	function mintAndRemix(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		MeemMintParameters memory remixParams,
		MeemProperties memory remixProperties,
		MeemProperties memory remixChildProperties
	) external payable override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.MINTER_ROLE);
		uint256 tokenId = LibMeem.mint(params, properties, childProperties);

		LibMeem.mint(
			MeemMintParameters({
				to: remixParams.to,
				tokenURI: remixParams.tokenURI,
				parentChain: remixParams.parentChain,
				parent: address(this),
				parentTokenId: tokenId,
				meemType: MeemType.Remix,
				data: remixParams.data,
				isURILocked: remixParams.isURILocked,
				mintedBy: remixParams.mintedBy,
				uriSource: remixParams.uriSource,
				reactionTypes: remixParams.reactionTypes
			}),
			remixProperties,
			remixChildProperties
		);
	}
}
