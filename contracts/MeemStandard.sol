// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface MeemStandard {
	enum Chain {
		Ethereum,
		Polygon,
		Cardano
	}

	enum Permission {
		Owner,
		Anyone,
		Addresses,
		Holders
	}

	/** The total number of copies allowed for a Meem */
	// function totalCopies(uint256 tokenId) external view returns (uint256);

	// function setTotalCopies(uint256 numCopies) external;

	/** The address of the parent contract NFT */
	function parent(uint256 tokenId) external view returns (address);

	/** The tokenId of the parent contract NFT */
	function parentTokenId(uint256 tokenId) external view returns (uint256);

	/** The chain of the parent contract NFT  */
	function parentChain(uint256 tokenId) external view returns (Chain);

	function copyPermission(uint256 tokenId) external view returns (Permission);

	function remixPermission(uint256 tokenId)
		external
		view
		returns (Permission);

	function readPermission(uint256 tokenId) external view returns (Permission);

	function copyPermissionAddresses(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function remixPermissionAddresses(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function readPermissionAddresses(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function copyPermissionNumTokens(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function remixPermissionNumTokens(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function readPermissionNumTokens(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function numSplits(uint256 tokenId) external view returns (uint256);

	function splitAddresses(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function splitAmounts(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function splitLockedBy(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function mint(
		string memory mTokenURI,
		address mTo,
		Chain mChain,
		address mParent,
		uint256 mParentTokenId,
		Permission[] memory mCopyRemixReadPermission,
		address[] memory mCopyPermissionAddresses,
		address[] memory mRemixPermissionAddresses,
		address[] memory mReadPermissionAddresses,
		address[] memory mCopyRemixReadLockedByAddress,
		address[] memory mSplitAddresses,
		uint256[] memory mSplitAmounts
	) external;
}
