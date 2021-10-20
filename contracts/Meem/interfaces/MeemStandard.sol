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
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	uint256 totalCopies;
	address totalCopiesLockedBy;
}

struct Meem {
	address owner;
	Chain chain;
	address parent;
	uint256 parentTokenId;
	MeemProperties properties;
	MeemProperties childProperties;
	uint256 totalSupply;
}

// mapping(uint256 => Chain) chain;
// mapping(uint256 => address) parent;
// mapping(uint256 => uint256) parentTokenId;
// mapping(uint256 => MeemProperties) properties;
// mapping(uint256 => MeemProperties) childProperties;

interface MeemStandard {
	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external;

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

	function setTotalCopies(uint256 tokenId, uint256 newTotalCopies) external;

	function lockTotalCopies(uint256 tokenId) external;

	// function addPermission(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	PermissionType permissionType,
	// 	MeemPermission memory permission
	// ) external;

	// function removePermissionAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	PermissionType permissionType,
	// 	uint256 idx
	// ) external;

	// function updatePermissionAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	PermissionType permissionType,
	// 	uint256 idx,
	// 	MeemPermission memory permission
	// ) external;

	// function addSplit(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	Split memory split
	// ) external;

	// function removeSplitAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	uint256 idx
	// ) external;

	// function updateSplitAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	uint256 idx,
	// 	Split memory split
	// ) external;
}
