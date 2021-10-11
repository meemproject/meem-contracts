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
	function totalCopies(uint256 tokenId) external view returns (uint256);

	/** The address of the parent contract NFT */
	function parent(uint256 tokenId) external view returns (address);

	/** The tokenId of the parent contract NFT */
	function parentTokenId(uint256 tokenId) external view returns (uint256);

	/** The chain of the parent contract NFT  */
	function parentChain(uint256 tokenId) external view returns (Chain);

	function copyPermission(uint256 tokenId) external view returns (Chain);

	function remixPermission(uint256 tokenId) external view returns (Chain);

	function readPermission(uint256 tokenId) external view returns (Chain);

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
		returns (uint256);

	function remixPermissionNumTokens(uint256 tokenId)
		external
		view
		returns (uint256);

	function readPermissionNumTokens(uint256 tokenId)
		external
		view
		returns (uint256);

	function numSplits(uint256 tokenId) external view returns (uint256);

	function splitAddress(uint256 tokenId, uint256 i)
		external
		view
		returns (address);

	function splitAmount(uint256 tokenId, uint256 i)
		external
		view
		returns (uint256);

	function splitLockedBy(uint256 tokenId, uint256 i)
		external
		view
		returns (address);
}
