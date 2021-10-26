// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Chain {
	Ethereum,
	Polygon,
	Cardano
}

enum PermissionType {
	Copy,
	Remix,
	Read
}

enum Permission {
	Owner,
	Anyone,
	Addresses,
	Holders
}

enum PropertyType {
	Meem,
	Child
}

struct Split {
	address toAddress;
	uint256 amount;
	address lockedBy;
}
struct MeemPermission {
	Permission permission;
	address[] addresses;
	uint256 numTokens;
	address lockedBy;
}

struct MeemProperties {
	int256 totalChildren;
	address totalChildrenLockedBy;
	int256 childrenPerWallet;
	address childrenPerWalletLockedBy;
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
}

struct Meem {
	address owner;
	Chain chain;
	address parent;
	uint256 parentTokenId;
	address root;
	uint256 rootTokenId;
	MeemProperties properties;
	MeemProperties childProperties;
}

interface IMeemStandard {
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

	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		address root,
		uint256 rootTokenId,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external returns (uint256 tokenId_);

	// TODO: Implement child minting
	// function mintChild(
	// 	address to,
	// 	string memory mTokenURI,
	// 	Chain chain,
	// 	uint256 parentTokenId,
	// 	MeemProperties memory properties,
	// 	MeemProperties memory childProperties
	// ) external;

	// Get children meems
	function childrenOf(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function numChildrenOf(uint256 tokenId) external view returns (uint256);

	function setTotalChildren(uint256 tokenId, int256 newTotalChildren)
		external;

	function lockTotalChildren(uint256 tokenId) external;

	function setChildrenPerWallet(uint256 tokenId, int256 newChildrenPerWallet)
		external;

	function lockChildrenPerWallet(uint256 tokenId) external;

	function setNonOwnerSplitAllocationAmount(uint256 amount) external;

	function nonOwnerSplitAllocationAmount() external view returns (uint256);

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) external;

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) external;

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) external;

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) external;

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) external;

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) external;

	function childDepth() external returns (uint256);

	function setChildDepth(uint256 newChildDepth) external;
}
