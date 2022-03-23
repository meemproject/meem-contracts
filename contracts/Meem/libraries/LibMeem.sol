// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {WrappedItem, IMeemPermissionsStandard, PropertyType, PermissionType, MeemPermission, MeemProperties, Split, URISource, MeemMintParameters, Meem, Chain, MeemType, MeemBase, Permission} from '../interfaces/MeemStandard.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {LibArray} from '../libraries/LibArray.sol';
import {LibPart} from '../../royalties/LibPart.sol';
import {LibStrings} from '../libraries/LibStrings.sol';
import {ERC721ReceiverNotImplemented, PropertyLocked, IndexOutOfRange, InvalidPropertyType, InvalidPermissionType, InvalidTotalCopies, NFTAlreadyWrapped, InvalidNonOwnerSplitAllocationAmount, TotalCopiesExceeded, CopiesPerWalletExceeded, NoPermission, InvalidChildGeneration, InvalidParent, ChildDepthExceeded, TokenNotFound, MissingRequiredPermissions, MissingRequiredSplits, NoChildOfCopy, InvalidURI, InvalidMeemType, NoCopyUnverified, TotalRemixesExceeded, RemixesPerWalletExceeded, InvalidTotalRemixes, AlreadyClipped, NotClipped, URILocked, IncorrectMsgValue} from '../libraries/Errors.sol';

library LibMeem {
	// Rarible royalties event
	event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

	// MeemStandard events
	event PermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);
	event SplitsSet(uint256 tokenId, PropertyType propertyType, Split[] splits);
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);
	event TotalCopiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	);
	event TotalCopiesLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event CopiesPerWalletSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event TotalRemixesSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event TotalRemixesLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event RemixesPerWalletSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event CopiesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event RemixesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);

	event TokenClipped(uint256 tokenId, address addy);

	event TokenUnClipped(uint256 tokenId, address addy);

	event URISourceSet(uint256 tokenId, URISource uriSource);

	event URISet(uint256 tokenId, string uri);

	event URILockedBySet(uint256 tokenId, address lockedBy);

	event DataSet(uint256 tokenId, string data);

	function getRaribleV2Royalties(uint256 tokenId)
		internal
		view
		returns (LibPart.Part[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		uint256 tokenIdToUse = s.meems[tokenId].meemType == MeemType.Copy
			? s.meems[tokenId].parentTokenId
			: tokenId;

		uint256 numSplits = s.meemProperties[tokenIdToUse].splits.length;
		LibPart.Part[] memory parts = new LibPart.Part[](numSplits);
		for (
			uint256 i = 0;
			i < s.meemProperties[tokenIdToUse].splits.length;
			i++
		) {
			parts[i] = LibPart.Part({
				account: payable(
					s.meemProperties[tokenIdToUse].splits[i].toAddress
				),
				value: uint96(s.meemProperties[tokenIdToUse].splits[i].amount)
			});
		}

		return parts;
	}

	function mint(
		MeemMintParameters memory params,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties
	) internal returns (uint256 tokenId_) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibMeem.requireValidMeem(
			params.parentChain,
			params.parent,
			params.parentTokenId
		);

		// Require IPFS uri
		if (
			params.uriSource != URISource.Data &&
			params.isURILocked &&
			!LibStrings.compareStrings(
				'ipfs://',
				LibStrings.substring(params.tokenURI, 0, 7)
			)
		) {
			revert InvalidURI();
		}

		uint256 tokenId = s.tokenCounter;
		LibERC721._safeMint(params.to, tokenId);

		// Initializes mapping w/ default values
		delete s.meems[tokenId];

		if (params.isURILocked) {
			s.meems[tokenId].uriLockedBy = msg.sender;
		}

		s.meems[tokenId].parentChain = params.parentChain;
		s.meems[tokenId].parent = params.parent;
		s.meems[tokenId].parentTokenId = params.parentTokenId;
		s.meems[tokenId].owner = params.to;
		s.meems[tokenId].mintedAt = block.timestamp;
		s.meems[tokenId].data = params.data;
		s.meems[tokenId].reactionTypes = params.reactionTypes;

		if (
			params.mintedBy != address(0) &&
			LibAccessControl.hasRole(s.MINTER_ROLE, msg.sender)
		) {
			s.meems[tokenId].mintedBy = params.mintedBy;
		} else {
			s.meems[tokenId].mintedBy = msg.sender;
		}

		// Handle creating child meem
		if (params.parent == address(this)) {
			// Verify token exists
			if (s.meems[params.parentTokenId].owner == address(0)) {
				revert TokenNotFound(params.parentTokenId);
			}
			// Verify we can mint based on permissions
			requireCanMintChildOf(
				params.to,
				params.meemType,
				params.parentTokenId
			);
			handleSaleDistribution(params.parentTokenId);

			// If parent is verified, this child is also verified
			// if (s.meems[params.parentTokenId].verifiedBy != address(0)) {
			// 	s.meems[tokenId].verifiedBy = address(this);
			// }

			if (params.meemType == MeemType.Copy) {
				// if (s.meems[params.parentTokenId].verifiedBy == address(0)) {
				// 	revert NoCopyUnverified();
				// }
				s.tokenURIs[tokenId] = s.tokenURIs[params.parentTokenId];
				s.meems[tokenId].meemType = MeemType.Copy;
			} else {
				s.tokenURIs[tokenId] = params.tokenURI;
				s.meems[tokenId].meemType = MeemType.Remix;
			}

			if (s.meems[params.parentTokenId].root != address(0)) {
				s.meems[tokenId].root = s.meems[params.parentTokenId].root;
				s.meems[tokenId].rootTokenId = s
					.meems[params.parentTokenId]
					.rootTokenId;
				s.meems[tokenId].rootChain = s
					.meems[params.parentTokenId]
					.rootChain;
			} else {
				s.meems[tokenId].root = params.parent;
				s.meems[tokenId].rootTokenId = params.parentTokenId;
				s.meems[tokenId].rootChain = params.parentChain;
			}

			s.meems[tokenId].generation =
				s.meems[params.parentTokenId].generation +
				1;

			// Merge parent childProperties into this child
			LibMeem.setProperties(
				tokenId,
				PropertyType.Meem,
				mProperties,
				params.parentTokenId,
				true
			);
			LibMeem.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties,
				params.parentTokenId,
				true
			);
		} else {
			s.meems[tokenId].generation = 0;
			s.meems[tokenId].root = params.parent;
			s.meems[tokenId].rootTokenId = params.parentTokenId;
			s.meems[tokenId].rootChain = params.parentChain;
			s.tokenURIs[tokenId] = params.tokenURI;
			if (params.parent == address(0)) {
				if (params.meemType != MeemType.Original) {
					revert InvalidMeemType();
				}
				s.meems[tokenId].meemType = MeemType.Original;
			} else {
				// Only trusted minter can mint a wNFT
				LibAccessControl.requireRole(s.MINTER_ROLE);
				if (params.meemType != MeemType.Wrapped) {
					revert InvalidMeemType();
				}
				s.meems[tokenId].meemType = MeemType.Wrapped;
			}
			LibMeem.setProperties(tokenId, PropertyType.Meem, mProperties);
			LibMeem.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties
			);
		}

		if (
			s.childDepth > -1 &&
			s.meems[tokenId].generation > uint256(s.childDepth)
		) {
			revert ChildDepthExceeded();
		}

		// Keep track of children Meems
		if (params.parent == address(this)) {
			if (s.meems[tokenId].meemType == MeemType.Copy) {
				s.copies[params.parentTokenId].push(tokenId);
				s.copiesOwnerTokens[params.parentTokenId][params.to].push(
					tokenId
				);
			} else if (s.meems[tokenId].meemType == MeemType.Remix) {
				s.remixes[params.parentTokenId].push(tokenId);
				s.remixesOwnerTokens[params.parentTokenId][params.to].push(
					tokenId
				);
			}
		} else if (params.parent != address(0)) {
			// Keep track of wrapped NFTs
			s.chainWrappedNFTs[params.parentChain][params.parent][
				params.parentTokenId
			] = tokenId;
		} else if (params.parent == address(0)) {
			s.originalMeemTokensIndex[tokenId] = s.originalMeemTokens.length;
			s.originalMeemTokens.push(tokenId);
		}

		if (s.meems[tokenId].root == address(this)) {
			s.decendants[s.meems[tokenId].rootTokenId].push(tokenId);
		}

		s.tokenCounter += 1;

		if (
			!LibERC721._checkOnERC721Received(
				address(0),
				params.to,
				tokenId,
				''
			)
		) {
			revert ERC721ReceiverNotImplemented();
		}

		return tokenId;
	}

	function lockPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		permissionNotLocked(props, permissionType);

		if (permissionType == PermissionType.Copy) {
			props.copyPermissionsLockedBy = msg.sender;
		} else if (permissionType == PermissionType.Remix) {
			props.remixPermissionsLockedBy = msg.sender;
		} else if (permissionType == PermissionType.Read) {
			props.readPermissionsLockedBy = msg.sender;
		} else {
			revert InvalidPermissionType();
		}
	}

	function setPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] memory permissions
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);

		// Check if there are any existing locked permissions and if so, verify they're the same as the new permissions
		validatePermissions(permissions, perms);

		if (permissionType == PermissionType.Copy) {
			delete props.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			delete props.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			delete props.readPermissions;
		} else {
			revert InvalidPermissionType();
		}

		for (uint256 i = 0; i < permissions.length; i++) {
			perms.push(permissions[i]);
		}

		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		perms.push(permission);

		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		if (perms[idx].lockedBy != address(0)) {
			revert PropertyLocked(perms[idx].lockedBy);
		}

		if (idx >= perms.length) {
			revert IndexOutOfRange(idx, perms.length - 1);
		}

		for (uint256 i = idx; i < perms.length - 1; i++) {
			perms[i] = perms[i + 1];
		}

		perms.pop();
		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);

		if (perms[idx].lockedBy != address(0)) {
			revert PropertyLocked(perms[idx].lockedBy);
		}

		perms[idx] = permission;
		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function lockSplits(uint256 tokenId, PropertyType propertyType) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}

		props.splitsLockedBy = msg.sender;
	}

	function setSplits(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] memory splits
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}

		validateOverrideSplits(splits, props.splits);

		delete props.splits;

		for (uint256 i = 0; i < splits.length; i++) {
			props.splits.push(splits[i]);
		}

		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);

		emit SplitsSet(tokenId, propertyType, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}
		props.splits.push(split);
		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);
		emit SplitsSet(tokenId, propertyType, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}

		if (props.splits[idx].lockedBy != address(0)) {
			revert PropertyLocked(props.splits[idx].lockedBy);
		}

		if (idx >= props.splits.length) {
			revert IndexOutOfRange(idx, props.splits.length - 1);
		}

		for (uint256 i = idx; i < props.splits.length - 1; i++) {
			props.splits[i] = props.splits[i + 1];
		}

		props.splits.pop();
		emit SplitsSet(tokenId, propertyType, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}

		if (props.splits[idx].lockedBy != address(0)) {
			revert PropertyLocked(props.splits[idx].lockedBy);
		}

		props.splits[idx] = split;
		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);
		emit SplitsSet(tokenId, propertyType, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function getMeem(uint256 tokenId) internal view returns (Meem memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		bool isCopy = s.meems[tokenId].meemType == MeemType.Copy;

		Meem memory meem = Meem(
			s.meems[tokenId].owner,
			s.meems[tokenId].parentChain,
			s.meems[tokenId].parent,
			s.meems[tokenId].parentTokenId,
			s.meems[tokenId].rootChain,
			s.meems[tokenId].root,
			s.meems[tokenId].rootTokenId,
			s.meems[tokenId].generation,
			isCopy
				? s.meemProperties[s.meems[tokenId].parentTokenId]
				: s.meemProperties[tokenId],
			isCopy
				? s.meemChildProperties[s.meems[tokenId].parentTokenId]
				: s.meemChildProperties[tokenId],
			s.meems[tokenId].mintedAt,
			isCopy
				? s.meems[s.meems[tokenId].parentTokenId].data
				: s.meems[tokenId].data,
			s.meems[tokenId].uriLockedBy,
			s.meems[tokenId].meemType,
			s.meems[tokenId].mintedBy,
			s.meems[tokenId].uriSource,
			s.meems[tokenId].reactionTypes
		);

		return meem;
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (propertyType == PropertyType.Meem) {
			return s.meemProperties[tokenId];
		} else if (propertyType == PropertyType.Child) {
			return s.meemChildProperties[tokenId];
		}

		revert InvalidPropertyType();
	}

	// Merges the base properties with any overrides
	function mergeProperties(
		MeemProperties memory baseProperties,
		MeemProperties memory overrideProps
	) internal pure returns (MeemProperties memory) {
		MeemProperties memory mergedProps = baseProperties;

		if (overrideProps.totalCopiesLockedBy != address(0)) {
			mergedProps.totalCopiesLockedBy = overrideProps.totalCopiesLockedBy;
			mergedProps.totalCopies = overrideProps.totalCopies;
		}

		if (overrideProps.copiesPerWalletLockedBy != address(0)) {
			mergedProps.copiesPerWalletLockedBy = overrideProps
				.copiesPerWalletLockedBy;
			mergedProps.copiesPerWallet = overrideProps.copiesPerWallet;
		}

		if (overrideProps.totalRemixesLockedBy != address(0)) {
			mergedProps.totalRemixesLockedBy = overrideProps
				.totalRemixesLockedBy;
			mergedProps.totalRemixes = overrideProps.totalRemixes;
		}

		if (overrideProps.remixesPerWalletLockedBy != address(0)) {
			mergedProps.remixesPerWalletLockedBy = overrideProps
				.remixesPerWalletLockedBy;
			mergedProps.remixesPerWallet = overrideProps.remixesPerWallet;
		}

		// Merge / validate properties
		if (overrideProps.copyPermissionsLockedBy != address(0)) {
			mergedProps.copyPermissionsLockedBy = overrideProps
				.copyPermissionsLockedBy;
			mergedProps.copyPermissions = overrideProps.copyPermissions;
		} else {
			validatePermissions(
				mergedProps.copyPermissions,
				overrideProps.copyPermissions
			);
		}

		if (overrideProps.remixPermissionsLockedBy != address(0)) {
			mergedProps.remixPermissionsLockedBy = overrideProps
				.remixPermissionsLockedBy;
			mergedProps.remixPermissions = overrideProps.remixPermissions;
		} else {
			validatePermissions(
				mergedProps.remixPermissions,
				overrideProps.remixPermissions
			);
		}

		if (overrideProps.readPermissionsLockedBy != address(0)) {
			mergedProps.readPermissionsLockedBy = overrideProps
				.readPermissionsLockedBy;
			mergedProps.readPermissions = overrideProps.readPermissions;
		} else {
			validatePermissions(
				mergedProps.readPermissions,
				overrideProps.readPermissions
			);
		}

		// Validate splits
		if (overrideProps.splitsLockedBy != address(0)) {
			mergedProps.splitsLockedBy = overrideProps.splitsLockedBy;
			mergedProps.splits = overrideProps.splits;
		} else {
			validateOverrideSplits(mergedProps.splits, overrideProps.splits);
		}

		return mergedProps;
	}

	function validatePermissions(
		MeemPermission[] memory basePermissions,
		MeemPermission[] memory overridePermissions
	) internal pure {
		for (uint256 i = 0; i < overridePermissions.length; i++) {
			if (overridePermissions[i].lockedBy != address(0)) {
				// Find the permission in basePermissions
				bool wasFound = false;
				for (uint256 j = 0; j < basePermissions.length; j++) {
					if (
						basePermissions[j].lockedBy ==
						overridePermissions[i].lockedBy &&
						basePermissions[j].permission ==
						overridePermissions[i].permission &&
						basePermissions[j].numTokens ==
						overridePermissions[i].numTokens &&
						addressArraysMatch(
							basePermissions[j].addresses,
							overridePermissions[i].addresses
						)
					) {
						wasFound = true;
						break;
					}
				}
				if (!wasFound) {
					revert MissingRequiredPermissions();
				}
			}
		}
	}

	function validateOverrideSplits(
		Split[] memory baseSplits,
		Split[] memory overrideSplits
	) internal pure {
		for (uint256 i = 0; i < overrideSplits.length; i++) {
			if (overrideSplits[i].lockedBy != address(0)) {
				// Find the permission in basePermissions
				bool wasFound = false;
				for (uint256 j = 0; j < baseSplits.length; j++) {
					if (
						baseSplits[j].lockedBy == overrideSplits[i].lockedBy &&
						baseSplits[j].amount == overrideSplits[i].amount &&
						baseSplits[j].toAddress == overrideSplits[i].toAddress
					) {
						wasFound = true;
						break;
					}
				}
				if (!wasFound) {
					revert MissingRequiredSplits();
				}
			}
		}
	}

	function addressArraysMatch(address[] memory arr1, address[] memory arr2)
		internal
		pure
		returns (bool)
	{
		if (arr1.length != arr2.length) {
			return false;
		}

		for (uint256 i = 0; i < arr1.length; i++) {
			if (arr1[i] != arr2[i]) {
				return false;
			}
		}

		return true;
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		setProperties(tokenId, propertyType, mProperties, 0, false);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties,
		uint256 parentTokenId,
		bool mergeParent
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);
		MeemProperties memory newProps = mProperties;
		if (mergeParent) {
			newProps = mergeProperties(
				mProperties,
				s.meemChildProperties[parentTokenId]
			);
		}

		for (uint256 i = 0; i < newProps.copyPermissions.length; i++) {
			props.copyPermissions.push(newProps.copyPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.remixPermissions.length; i++) {
			props.remixPermissions.push(newProps.remixPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.readPermissions.length; i++) {
			props.readPermissions.push(newProps.readPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.splits.length; i++) {
			props.splits.push(newProps.splits[i]);
		}

		props.totalCopies = newProps.totalCopies;
		props.totalCopiesLockedBy = newProps.totalCopiesLockedBy;
		props.totalRemixes = newProps.totalRemixes;
		props.totalRemixesLockedBy = newProps.totalRemixesLockedBy;
		props.copiesPerWallet = newProps.copiesPerWallet;
		props.copiesPerWalletLockedBy = newProps.copiesPerWalletLockedBy;
		props.remixesPerWallet = newProps.remixesPerWallet;
		props.remixesPerWalletLockedBy = newProps.remixesPerWalletLockedBy;
		props.copyPermissionsLockedBy = newProps.copyPermissionsLockedBy;
		props.remixPermissionsLockedBy = newProps.remixPermissionsLockedBy;
		props.readPermissionsLockedBy = newProps.readPermissionsLockedBy;
		props.splitsLockedBy = newProps.splitsLockedBy;

		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);

		emit PropertiesSet(tokenId, propertyType, props);
	}

	function permissionNotLocked(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view {
		if (permissionType == PermissionType.Copy) {
			if (self.copyPermissionsLockedBy != address(0)) {
				revert PropertyLocked(self.copyPermissionsLockedBy);
			}
		} else if (permissionType == PermissionType.Remix) {
			if (self.remixPermissionsLockedBy != address(0)) {
				revert PropertyLocked(self.remixPermissionsLockedBy);
			}
		} else if (permissionType == PermissionType.Read) {
			if (self.readPermissionsLockedBy != address(0)) {
				revert PropertyLocked(self.readPermissionsLockedBy);
			}
		}
	}

	function validateSplits(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) internal view {
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

		if (
			totalAmount > 10000 ||
			totalAmountOfNonOwner < nonOwnerSplitAllocationAmount
		) {
			revert InvalidNonOwnerSplitAllocationAmount(
				nonOwnerSplitAllocationAmount,
				10000
			);
		}
	}

	function handleSaleDistribution(uint256 tokenId) internal {
		if (msg.value == 0) {
			return;
		}

		uint256 leftover = msg.value;

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		for (uint256 i = 0; i < s.meemProperties[tokenId].splits.length; i++) {
			uint256 amt = (msg.value *
				s.meemProperties[tokenId].splits[i].amount) / 10000;

			address payable receiver = payable(
				s.meemProperties[tokenId].splits[i].toAddress
			);

			receiver.transfer(amt);
			leftover = leftover - amt;
		}

		if (leftover > 0) {
			payable(s.meems[tokenId].owner).transfer(leftover);
		}
	}

	function getPermissions(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view returns (MeemPermission[] storage) {
		if (permissionType == PermissionType.Copy) {
			return self.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			return self.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			return self.readPermissions;
		}

		revert InvalidPermissionType();
	}

	function setTotalCopies(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (newTotalCopies > -1) {
			if (
				propertyType == PropertyType.Meem &&
				uint256(newTotalCopies) < s.copies[tokenId].length
			) {
				revert InvalidTotalCopies(s.copies[tokenId].length);
			}
		}

		if (props.totalCopiesLockedBy != address(0)) {
			revert PropertyLocked(props.totalCopiesLockedBy);
		}

		props.totalCopies = newTotalCopies;
		emit TotalCopiesSet(tokenId, propertyType, newTotalCopies);
	}

	function lockTotalCopies(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.totalCopiesLockedBy != address(0)) {
			revert PropertyLocked(props.totalCopiesLockedBy);
		}

		props.totalCopiesLockedBy = msg.sender;
		emit TotalCopiesLocked(tokenId, propertyType, msg.sender);
	}

	function setCopiesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.copiesPerWalletLockedBy != address(0)) {
			revert PropertyLocked(props.copiesPerWalletLockedBy);
		}

		props.copiesPerWallet = newTotalCopies;
		emit CopiesPerWalletSet(tokenId, propertyType, newTotalCopies);
	}

	function lockCopiesPerWallet(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.copiesPerWalletLockedBy != address(0)) {
			revert PropertyLocked(props.copiesPerWalletLockedBy);
		}

		props.copiesPerWalletLockedBy = msg.sender;
		emit CopiesPerWalletLocked(tokenId, propertyType, msg.sender);
	}

	function setTotalRemixes(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (newTotalRemixes > -1) {
			if (
				propertyType == PropertyType.Meem &&
				uint256(newTotalRemixes) < s.remixes[tokenId].length
			) {
				revert InvalidTotalRemixes(s.remixes[tokenId].length);
			}
		}

		if (props.totalRemixesLockedBy != address(0)) {
			revert PropertyLocked(props.totalRemixesLockedBy);
		}

		props.totalRemixes = newTotalRemixes;
		emit TotalRemixesSet(tokenId, propertyType, newTotalRemixes);
	}

	function lockTotalRemixes(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.totalRemixesLockedBy != address(0)) {
			revert PropertyLocked(props.totalRemixesLockedBy);
		}

		props.totalRemixesLockedBy = msg.sender;
		emit TotalRemixesLocked(tokenId, propertyType, msg.sender);
	}

	function setRemixesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.remixesPerWalletLockedBy != address(0)) {
			revert PropertyLocked(props.remixesPerWalletLockedBy);
		}

		props.remixesPerWallet = newTotalRemixes;
		emit RemixesPerWalletSet(tokenId, propertyType, newTotalRemixes);
	}

	function lockRemixesPerWallet(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.remixesPerWalletLockedBy != address(0)) {
			revert PropertyLocked(props.remixesPerWalletLockedBy);
		}

		props.remixesPerWalletLockedBy = msg.sender;
		emit RemixesPerWalletLocked(tokenId, propertyType, msg.sender);
	}

	function requireValidMeem(
		Chain chain,
		address parent,
		uint256 tokenId
	) internal view {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		// Meem must be unique address(0) or not have a corresponding parent / tokenId already minted
		if (parent != address(0) && parent != address(this)) {
			if (s.chainWrappedNFTs[chain][parent][tokenId] != 0) {
				revert NFTAlreadyWrapped(parent, tokenId);
				// revert('NFT_ALREADY_WRAPPED');
			}
		}
	}

	function isNFTWrapped(
		Chain chainId,
		address contractAddress,
		uint256 tokenId
	) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.chainWrappedNFTs[chainId][contractAddress][tokenId] != 0) {
			return true;
		}

		return false;
	}

	function wrappedTokens(WrappedItem[] memory items)
		internal
		view
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		uint256[] memory result = new uint256[](items.length);

		for (uint256 i = 0; i < items.length; i++) {
			result[i] = s.chainWrappedNFTs[items[i].chain][
				items[i].contractAddress
			][items[i].tokenId];
		}

		return result;
	}

	// Checks if "to" can mint a child of tokenId
	function requireCanMintChildOf(
		address to,
		MeemType meemType,
		uint256 tokenId
	) internal view {
		if (meemType != MeemType.Copy && meemType != MeemType.Remix) {
			revert NoPermission();
		}

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemBase storage parent = s.meems[tokenId];

		// Only allow copies if the parent is an original or remix (i.e. no copies of a copy)
		if (parent.meemType == MeemType.Copy) {
			revert NoChildOfCopy();
		}

		MeemProperties storage parentProperties = s.meemProperties[tokenId];
		// uint256 currentChildren = s.children[tokenId].length;

		// Check total children
		if (
			meemType == MeemType.Copy &&
			parentProperties.totalCopies >= 0 &&
			s.copies[tokenId].length + 1 > uint256(parentProperties.totalCopies)
		) {
			revert TotalCopiesExceeded();
		} else if (
			meemType == MeemType.Remix &&
			parentProperties.totalRemixes >= 0 &&
			s.remixes[tokenId].length + 1 >
			uint256(parentProperties.totalRemixes)
		) {
			revert TotalRemixesExceeded();
		}

		if (
			meemType == MeemType.Copy &&
			parentProperties.copiesPerWallet >= 0 &&
			s.copiesOwnerTokens[tokenId][to].length + 1 >
			uint256(parentProperties.copiesPerWallet)
		) {
			revert CopiesPerWalletExceeded();
		} else if (
			meemType == MeemType.Remix &&
			parentProperties.remixesPerWallet >= 0 &&
			s.remixesOwnerTokens[tokenId][to].length + 1 >
			uint256(parentProperties.remixesPerWallet)
		) {
			revert RemixesPerWalletExceeded();
		}

		// Check permissions
		MeemPermission[] storage perms = getPermissions(
			parentProperties,
			meemTypeToPermissionType(meemType)
		);

		bool hasPermission = false;
		bool hasCostBeenSet = false;
		uint256 costWei = 0;

		for (uint256 i = 0; i < perms.length; i++) {
			MeemPermission storage perm = perms[i];
			if (
				// Allowed if permission is anyone
				perm.permission == Permission.Anyone ||
				// Allowed if permission is owner and the minter is the owner
				(perm.permission == Permission.Owner &&
					parent.owner == msg.sender)
			) {
				hasPermission = true;
			}

			if (perm.permission == Permission.Addresses) {
				// Allowed if to is in the list of approved addresses
				for (uint256 j = 0; j < perm.addresses.length; j++) {
					if (perm.addresses[j] == msg.sender) {
						hasPermission = true;
						break;
					}
				}
			}

			if (
				hasPermission &&
				(!hasCostBeenSet || (hasCostBeenSet && costWei > perm.costWei))
			) {
				costWei = perm.costWei;
				hasCostBeenSet = true;
			}
			// TODO: Check external token holders on same network
		}

		if (!hasPermission) {
			revert NoPermission();
		}

		if (costWei != msg.value) {
			revert IncorrectMsgValue();
		}
	}

	function permissionTypeToMeemType(PermissionType perm)
		internal
		pure
		returns (MeemType)
	{
		if (perm == PermissionType.Copy) {
			return MeemType.Copy;
		} else if (perm == PermissionType.Remix) {
			return MeemType.Remix;
		}

		revert NoPermission();
	}

	function meemTypeToPermissionType(MeemType meemType)
		internal
		pure
		returns (PermissionType)
	{
		if (meemType == MeemType.Copy) {
			return PermissionType.Copy;
		} else if (meemType == MeemType.Remix) {
			return PermissionType.Remix;
		}

		revert NoPermission();
	}

	function clip(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.hasAddressClipped[msg.sender][tokenId]) {
			revert AlreadyClipped();
		}

		s.clippings[tokenId].push(msg.sender);
		s.addressClippings[msg.sender].push(tokenId);
		s.clippingsIndex[msg.sender][tokenId] = s.clippings[tokenId].length - 1;
		s.addressClippingsIndex[msg.sender][tokenId] =
			s.addressClippings[msg.sender].length -
			1;
		s.hasAddressClipped[msg.sender][tokenId] = true;

		emit TokenClipped(tokenId, msg.sender);
	}

	function unClip(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!s.hasAddressClipped[msg.sender][tokenId]) {
			revert NotClipped();
		}

		LibArray.removeAt(
			s.clippings[tokenId],
			s.clippingsIndex[msg.sender][tokenId]
		);
		LibArray.removeAt(
			s.addressClippings[msg.sender],
			s.addressClippingsIndex[msg.sender][tokenId]
		);
		s.clippingsIndex[msg.sender][tokenId] = 0;
		s.addressClippingsIndex[msg.sender][tokenId] = 0;
		s.hasAddressClipped[msg.sender][tokenId] = false;

		emit TokenUnClipped(tokenId, msg.sender);
	}

	function tokenClippings(uint256 tokenId)
		internal
		view
		returns (address[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippings[tokenId];
	}

	function addressClippings(address addy)
		internal
		view
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.addressClippings[addy];
	}

	function hasAddressClipped(uint256 tokenId, address addy)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippingsIndex[addy][tokenId] != 0;
	}

	function clippings(uint256 tokenId)
		internal
		view
		returns (address[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippings[tokenId];
	}

	function numClippings(uint256 tokenId) internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippings[tokenId].length;
	}

	function setData(uint256 tokenId, string memory data) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert URILocked();
		}

		s.meems[tokenId].data = data;
		emit DataSet(tokenId, s.meems[tokenId].data);
	}

	function lockUri(uint256 tokenId) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert URILocked();
		}

		// Require IPFS uri or URI type to be data
		if (
			s.meems[tokenId].uriSource != URISource.Data &&
			!LibStrings.compareStrings(
				'ipfs://',
				LibStrings.substring(s.tokenURIs[tokenId], 0, 7)
			)
		) {
			revert InvalidURI();
		}

		s.meems[tokenId].uriLockedBy = msg.sender;

		emit URILockedBySet(tokenId, s.meems[tokenId].uriLockedBy);
	}

	function setURISource(uint256 tokenId, URISource uriSource) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert URILocked();
		}

		s.meems[tokenId].uriSource = uriSource;
		emit URISourceSet(tokenId, uriSource);
	}

	function setTokenUri(uint256 tokenId, string memory uri) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert URILocked();
		}

		s.tokenURIs[tokenId] = uri;

		emit URISet(tokenId, uri);
	}
}
