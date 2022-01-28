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
	) external override {
		LibMeem.mint(params, properties, childProperties);
	}

	function mintAndCopy(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		address toCopyAddress
	) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.MINTER_ROLE);
		uint256 tokenId = LibMeem.mint(params, properties, childProperties);

		LibMeem.mint(
			MeemMintParameters({
				to: toCopyAddress,
				mTokenURI: params.mTokenURI,
				parentChain: params.parentChain,
				parent: address(this),
				parentTokenId: tokenId,
				meemType: MeemType.Copy,
				data: params.data,
				isVerified: params.isVerified,
				mintedBy: params.mintedBy
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
	) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.MINTER_ROLE);
		uint256 tokenId = LibMeem.mint(params, properties, childProperties);

		LibMeem.mint(
			MeemMintParameters({
				to: remixParams.to,
				mTokenURI: remixParams.mTokenURI,
				parentChain: remixParams.parentChain,
				parent: address(this),
				parentTokenId: tokenId,
				meemType: MeemType.Remix,
				data: remixParams.data,
				isVerified: remixParams.isVerified,
				mintedBy: remixParams.mintedBy
			}),
			remixProperties,
			remixChildProperties
		);
	}
}
