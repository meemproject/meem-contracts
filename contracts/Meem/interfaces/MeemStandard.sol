// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Chain {
	Ethereum,
	Polygon,
	Cardano,
	Solana,
	Rinkeby
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

enum MeemType {
	Original,
	Copy,
	Remix,
	Wrapped
}

enum URISource {
	TokenURI,
	Data
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
	uint256 costWei;
}

struct MeemProperties {
	int256 totalRemixes;
	address totalRemixesLockedBy;
	int256 remixesPerWallet;
	address remixesPerWalletLockedBy;
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	int256 totalCopies;
	address totalCopiesLockedBy;
	int256 copiesPerWallet;
	address copiesPerWalletLockedBy;
}

struct MeemBase {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	uint256 mintedAt;
	string data;
	address uriLockedBy;
	MeemType meemType;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct Meem {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	MeemProperties properties;
	MeemProperties childProperties;
	uint256 mintedAt;
	string data;
	address uriLockedBy;
	MeemType meemType;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct WrappedItem {
	Chain chain;
	address contractAddress;
	uint256 tokenId;
}

struct MeemMintParameters {
	address to;
	string tokenURI;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	MeemType meemType;
	string data;
	bool isURILocked;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct Reaction {
	string reaction;
	uint256 count;
}

interface IMeemBaseStandard {
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);

	function mint(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external payable;

	function mintAndCopy(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		address toCopyAddress
	) external payable;

	function mintAndRemix(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		MeemMintParameters memory remixParams,
		MeemProperties memory remixProperties,
		MeemProperties memory remixChildProperties
	) external payable;

	// TODO: Implement child minting
	// function mintChild(
	// 	address to,
	// 	string memory mTokenURI,
	// 	Chain chain,
	// 	uint256 parentTokenId,
	// 	MeemProperties memory properties,
	// 	MeemProperties memory childProperties
	// ) external;
}

interface IMeemQueryStandard {
	// Get children meems
	function copiesOf(uint256 tokenId) external view returns (uint256[] memory);

	function ownedCopiesOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numCopiesOf(uint256 tokenId) external view returns (uint256);

	function remixesOf(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function ownedRemixesOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numRemixesOf(uint256 tokenId) external view returns (uint256);

	function childDepth() external returns (int256);

	function tokenIdsOfOwner(address _owner)
		external
		view
		returns (uint256[] memory tokenIds_);

	function isNFTWrapped(
		Chain chain,
		address contractAddress,
		uint256 tokenId
	) external view returns (bool);

	function wrappedTokens(WrappedItem[] memory items)
		external
		view
		returns (uint256[] memory);

	function getMeem(uint256 tokenId) external view returns (Meem memory);
}

interface IMeemAdminStandard {
	function setNonOwnerSplitAllocationAmount(uint256 amount) external;

	function setChildDepth(int256 newChildDepth) external;

	function setTokenCounter(uint256 tokenCounter) external;

	function setContractURI(string memory newContractURI) external;

	function setMeemIDAddress(address meemID) external;

	function setTokenRoot(
		uint256 tokenId,
		Chain rootChain,
		address root,
		uint256 rootTokenId
	) external;
}

interface IMeemSplitsStandard {
	event SplitsSet(uint256 tokenId, PropertyType propertyType, Split[] splits);

	function nonOwnerSplitAllocationAmount() external view returns (uint256);

	function lockSplits(uint256 tokenId, PropertyType propertyType) external;

	function setSplits(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] memory splits
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
}

interface IMeemPermissionsStandard {
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
		int256 newTotalCopies
	);
	event CopiesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
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
	event RemixesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);

	event PermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);

	event URISourceSet(uint256 tokenId, URISource uriSource);

	event URISet(uint256 tokenId, string uri);

	event URILockedBySet(uint256 tokenId, address lockedBy);

	event DataSet(uint256 tokenId, string data);

	function lockPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType
	) external;

	function setPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] memory permissions
	) external;

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

	function setTotalCopies(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) external;

	function lockTotalCopies(uint256 tokenId, PropertyType propertyType)
		external;

	function setCopiesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newChildrenPerWallet
	) external;

	function lockCopiesPerWallet(uint256 tokenId, PropertyType propertyType)
		external;

	function setTotalRemixes(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) external;

	function lockTotalRemixes(uint256 tokenId, PropertyType propertyType)
		external;

	function setRemixesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newChildrenPerWallet
	) external;

	function lockRemixesPerWallet(uint256 tokenId, PropertyType propertyType)
		external;

	function setData(uint256 tokenId, string memory data) external;

	function lockUri(uint256 tokenId) external;

	function setURISource(uint256 tokenId, URISource uriSource) external;

	function setTokenUri(uint256 tokenId, string memory uri) external;
}

interface IClippingStandard {
	event TokenClipped(uint256 tokenId, address addy);

	event TokenUnClipped(uint256 tokenId, address addy);

	function clip(uint256 tokenId) external;

	function unClip(uint256 tokenId) external;

	function addressClippings(address addy)
		external
		view
		returns (uint256[] memory);

	function hasAddressClipped(uint256 tokenId, address addy)
		external
		view
		returns (bool);

	function clippings(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function numClippings(uint256 tokenId) external view returns (uint256);
}

interface IReactionStandard {
	event TokenReactionAdded(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event TokenReactionRemoved(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event TokenReactionTypesSet(uint256 tokenId, string[] reactionTypes);

	function addReaction(uint256 tokenId, string memory reaction) external;

	function removeReaction(uint256 tokenId, string memory reaction) external;

	function getReactedAt(
		uint256 tokenId,
		address addy,
		string memory reaction
	) external view returns (uint256);

	function setReactionTypes(uint256 tokenId, string[] memory reactionTypes)
		external;

	function getReactions(uint256 tokenId)
		external
		view
		returns (Reaction[] memory);
}
