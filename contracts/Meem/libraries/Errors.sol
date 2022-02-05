// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error MissingRequiredRole(bytes32 requiredRole);

error NotTokenOwner(uint256 tokenId);

error NotTokenAdmin(uint256 tokenId);

error InvalidNonOwnerSplitAllocationAmount(
	uint256 minAmount,
	uint256 maxAmount
);

error NoRenounceOthers();

error InvalidZeroAddressQuery();

error IndexOutOfRange(uint256 idx, uint256 max);

error TokenNotFound(uint256 tokenId);

error TokenAlreadyExists(uint256 tokenId);

error NoApproveSelf();

error NotApproved();

error ERC721ReceiverNotImplemented();

error ToAddressInvalid(address to);

error NoTransferWrappedNFT(address parentAddress, uint256 parentTokenId);

error NFTAlreadyWrapped(address parentAddress, uint256 parentTokenId);

error PropertyLocked(address lockedBy);

error InvalidPropertyType();

error InvalidPermissionType();

error InvalidTotalCopies(uint256 currentTotalCopies);

error TotalCopiesExceeded();

error InvalidTotalRemixes(uint256 currentTotalRemixes);

error TotalRemixesExceeded();

error CopiesPerWalletExceeded();

error RemixesPerWalletExceeded();

error NoPermission();

error InvalidChildGeneration();

error InvalidParent();

error ChildDepthExceeded();

error MissingRequiredPermissions();

error MissingRequiredSplits();

error NoChildOfCopy();

error NoCopyUnverified();

error MeemNotVerified();

error InvalidURI();

error InvalidMeemType();

error InvalidToken();
