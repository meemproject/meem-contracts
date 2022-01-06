// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '../interfaces/MeemStandard.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {LibPart} from '../../royalties/LibPart.sol';
import {ERC721ReceiverNotImplemented, PropertyLocked, IndexOutOfRange, InvalidPropertyType, InvalidPermissionType, InvalidTotalChildren, NFTAlreadyWrapped, InvalidNonOwnerSplitAllocationAmount, TotalChildrenExceeded, ChildrenPerWalletExceeded, NoPermission, InvalidChildGeneration, InvalidParent, ChildDepthExceeded, TokenNotFound, MissingRequiredPermissions, MissingRequiredSplits} from '../libraries/Errors.sol';

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
	event SplitsSet(uint256 tokenId, Split[] splits);
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);
	event TotalChildrenSet(uint256 tokenId, int256 newTotalChildren);
	event TotalChildrenLocked(uint256 tokenId, address lockedBy);
	event ChildrenPerWalletSet(uint256 tokenId, int256 newTotalChildren);
	event ChildrenPerWalletLocked(uint256 tokenId, address lockedBy);

	function getRaribleV2Royalties(uint256 tokenId)
		internal
		view
		returns (LibPart.Part[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		uint256 numSplits = s.meemProperties[tokenId].splits.length;
		LibPart.Part[] memory parts = new LibPart.Part[](numSplits);
		for (uint256 i = 0; i < s.meemProperties[tokenId].splits.length; i++) {
			parts[i] = LibPart.Part({
				account: payable(s.meemProperties[tokenId].splits[i].toAddress),
				value: uint96(s.meemProperties[tokenId].splits[i].amount)
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
		uint256 tokenId = s.tokenCounter;
		LibERC721._safeMint(params.to, tokenId);
		s.tokenURIs[tokenId] = params.mTokenURI;

		if (params.root == address(this) && params.parent != address(this)) {
			revert InvalidParent();
		}

		// Initializes mapping w/ default values
		delete s.meems[tokenId];

		s.meems[tokenId].parentChain = params.parentChain;
		s.meems[tokenId].rootChain = params.rootChain;
		s.meems[tokenId].parent = params.parent;
		s.meems[tokenId].parentTokenId = params.parentTokenId;
		s.meems[tokenId].root = params.root;
		s.meems[tokenId].rootTokenId = params.rootTokenId;
		s.meems[tokenId].owner = params.to;
		s.meems[tokenId].mintedAt = block.timestamp;
		s.meems[tokenId].data = params.data;

		// Set generation of Meem
		if (params.parent == address(this)) {
			// Verify token exists
			if (s.meems[params.parentTokenId].owner == address(0)) {
				revert TokenNotFound(params.parentTokenId);
			}
			// Verify we can mint based on permissions
			requireCanMintChildOf(
				params.to,
				params.permissionType,
				params.parentTokenId
			);

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
			// Gen 0 Meems require minter role
			LibAccessControl.requireRole(s.MINTER_ROLE);
			s.meems[tokenId].generation = 0;
			LibMeem.setProperties(tokenId, PropertyType.Meem, mProperties);
			LibMeem.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties
			);
		}

		if (s.meems[tokenId].generation > s.childDepth) {
			revert ChildDepthExceeded();
		}

		// Keep track of children Meems
		if (params.parent == address(this)) {
			s.children[params.parentTokenId].push(tokenId);
			s.childrenOwnerTokens[params.parentTokenId][params.to].push(
				tokenId
			);
		} else if (params.parent != address(0)) {
			// Keep track of wrapped NFTs
			s.chainWrappedNFTs[params.parentChain][params.parent][
				params.parentTokenId
			] = tokenId;
		} else if (params.parent == address(0)) {
			s.originalMeemTokensIndex[tokenId] = s.originalMeemTokens.length;
			s.originalMeemTokens.push(tokenId);
		}

		if (params.root == address(this)) {
			s.decendants[params.rootTokenId].push(tokenId);
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
		emit SplitsSet(tokenId, props.splits);
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
		emit SplitsSet(tokenId, props.splits);
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
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function getMeem(uint256 tokenId) internal view returns (Meem memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		Meem memory meem = Meem(
			s.meems[tokenId].owner,
			s.meems[tokenId].parentChain,
			s.meems[tokenId].parent,
			s.meems[tokenId].parentTokenId,
			s.meems[tokenId].rootChain,
			s.meems[tokenId].root,
			s.meems[tokenId].rootTokenId,
			s.meems[tokenId].generation,
			s.meemProperties[tokenId],
			s.meemChildProperties[tokenId],
			s.meems[tokenId].mintedAt,
			s.meems[tokenId].data
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

		if (overrideProps.totalChildrenLockedBy != address(0)) {
			mergedProps.totalChildrenLockedBy = overrideProps
				.totalChildrenLockedBy;
			mergedProps.totalChildren = overrideProps.totalChildren;
		}

		if (overrideProps.childrenPerWalletLockedBy != address(0)) {
			mergedProps.childrenPerWalletLockedBy = overrideProps
				.childrenPerWalletLockedBy;
			mergedProps.childrenPerWallet = overrideProps.childrenPerWallet;
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

		props.totalChildren = newProps.totalChildren;
		props.totalChildrenLockedBy = newProps.totalChildrenLockedBy;
		props.childrenPerWallet = newProps.childrenPerWallet;
		props.childrenPerWalletLockedBy = newProps.childrenPerWalletLockedBy;
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

	function setTotalChildren(uint256 tokenId, int256 newTotalChildren)
		internal
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (newTotalChildren > -1) {
			if (uint256(newTotalChildren) < s.children[tokenId].length) {
				revert InvalidTotalChildren(s.children[tokenId].length);
			}
		}

		if (s.meemProperties[tokenId].totalChildrenLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].totalChildrenLockedBy
			);
		}

		s.meemProperties[tokenId].totalChildren = newTotalChildren;
		emit TotalChildrenSet(tokenId, newTotalChildren);
	}

	function lockTotalChildren(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (s.meemProperties[tokenId].totalChildrenLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].totalChildrenLockedBy
			);
		}

		s.meemProperties[tokenId].totalChildrenLockedBy = msg.sender;
		emit TotalChildrenLocked(tokenId, msg.sender);
	}

	function setChildrenPerWallet(uint256 tokenId, int256 newTotalChildren)
		internal
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (s.meemProperties[tokenId].childrenPerWalletLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].childrenPerWalletLockedBy
			);
		}

		s.meemProperties[tokenId].childrenPerWallet = newTotalChildren;
		emit ChildrenPerWalletSet(tokenId, newTotalChildren);
	}

	function lockChildrenPerWallet(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (s.meemProperties[tokenId].childrenPerWalletLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].childrenPerWalletLockedBy
			);
		}

		s.meemProperties[tokenId].childrenPerWalletLockedBy = msg.sender;
		emit ChildrenPerWalletLocked(tokenId, msg.sender);
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
		PermissionType permissionType,
		uint256 tokenId
	) internal view {
		if (
			permissionType != PermissionType.Copy &&
			permissionType != PermissionType.Remix
		) {
			revert NoPermission();
		}

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemBase storage parent = s.meems[tokenId];
		MeemProperties storage parentProperties = s.meemProperties[tokenId];
		uint256 currentChildren = s.children[tokenId].length;

		// Check total children
		if (
			parentProperties.totalChildren >= 0 &&
			currentChildren + 1 > uint256(parentProperties.totalChildren)
		) {
			revert TotalChildrenExceeded();
		}

		// Check total children per wallet
		uint256 numChildrenAlreadyHeld = s
		.childrenOwnerTokens[tokenId][to].length;
		if (
			parentProperties.childrenPerWallet >= 0 &&
			numChildrenAlreadyHeld + 1 >
			uint256(parentProperties.childrenPerWallet)
		) {
			revert ChildrenPerWalletExceeded();
		}

		// If user doesn't have the minter role, check permissions
		// if (!LibAccessControl.hasRole(s.MINTER_ROLE, msg.sender)) {
		// Check permissions
		MeemPermission[] storage perms = getPermissions(
			parentProperties,
			permissionType
		);

		bool hasPermission = false;
		for (uint256 i = 0; i < perms.length; i++) {
			MeemPermission storage perm = perms[i];
			if (
				// Allowed if permission is anyone
				perm.permission == Permission.Anyone ||
				// Allowed if permission is owner and this is the owner
				(perm.permission == Permission.Owner && parent.owner == to)
			) {
				hasPermission = true;
				break;
			} else if (perm.permission == Permission.Addresses) {
				// Allowed if to is in the list of approved addresses
				for (uint256 j = 0; j < perm.addresses.length; j++) {
					if (perm.addresses[j] == to) {
						hasPermission = true;
						break;
					}
				}

				if (hasPermission) {
					break;
				}
			}
		}

		if (!hasPermission) {
			revert NoPermission();
		}
		// }
	}
}
