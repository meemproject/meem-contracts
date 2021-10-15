// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';

import './ERC721TradableUpgradeable.sol';
import './Base64.sol';
import './MeemStandard.sol';

contract Meem is
	ERC721TradableUpgradeable,
	AccessControlUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	UUPSUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721EnumerableUpgradeable,
	ERC721URIStorageUpgradeable,
	MeemStandard
{
	using CountersUpgradeable for CountersUpgradeable.Counter;
	using StringsUpgradeable for uint256;

	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
	bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

	CountersUpgradeable.Counter private _tokenIdCounter;

	address private _tokenURIContractAddress;
	string private _contractURI;
	uint256 private nonOwnerSplitAllocationAmount = 1000;
	mapping(uint256 => Chain) private _chain;
	mapping(uint256 => address) private _parent;
	mapping(uint256 => uint256) private _parentTokenId;
	mapping(uint256 => MeemProperties) private _properties;
	mapping(uint256 => MeemProperties) private _childProperties;
	mapping(uint256 => string) private _tokenURIs;
	mapping(uint256 => uint256[]) private _children;

	function initialize(address _proxyRegistryAddress) public initializer {
		__ERC721Tradable_init('Meem', 'MEEM', _proxyRegistryAddress);
		__ERC721Enumerable_init();
		__ERC721URIStorage_init();
		__Pausable_init();
		__Ownable_init();
		__AccessControl_init();
		__ERC721Burnable_init();
		__UUPSUpgradeable_init();

		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(PAUSER_ROLE, msg.sender);
		_setupRole(MINTER_ROLE, msg.sender);
		_setupRole(UPGRADER_ROLE, msg.sender);

		_contractURI = '{"name": "Meem","description": "Meems are pieces of digital content wrapped in more advanced dynamic property rights. They are ideas, stories, images -- existing independently from any social platform -- whose creators have set the terms by which others can access, remix, and share in their value. Join us at https://discord.gg/5NP8PYN8","image": "https://meem-assets.s3.amazonaws.com/meem.jpg","external_link": "https://meem.wtf","seller_fee_basis_points": 1000, "fee_recipient": "0x40c6BeE45d94063c5B05144489cd8A9879899592"}';
	}

	// External functions
	// ...

	// External view functions
	// ...

	// External pure functions
	// ...

	// Public functions
	function isApprovedForAll(address owner, address operator)
		public
		view
		override(ERC721TradableUpgradeable, ERC721Upgradeable)
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(
			ERC721Upgradeable,
			AccessControlUpgradeable,
			ERC721EnumerableUpgradeable
		)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties
	) public override onlyRole(MINTER_ROLE) {
		uint256 tokenId = _tokenIdCounter.current();
		_safeMint(to, tokenId);
		_tokenURIs[tokenId] = mTokenURI;
		validateSplits(tokenId, mProperties.splits);
		validateSplits(tokenId, mChildProperties.splits);

		// Initializes mapping w/ default values
		delete _properties[tokenId];
		delete _childProperties[tokenId];

		_chain[tokenId] = chain;
		_parent[tokenId] = parent;
		_parentTokenId[tokenId] = parentTokenId;

		setProperties(tokenId, PropertyType.Meem, mProperties);
		setProperties(tokenId, PropertyType.Child, mChildProperties);

		// Keep track of children Meems
		if (parent == address(this)) {
			_children[parentTokenId].push(tokenId);
		}

		_tokenIdCounter.increment();
	}

	function setContractURI(string memory newContractURI)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_contractURI = newContractURI;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
		returns (string memory)
	{
		return _tokenURIs[tokenId];
	}

	function setTokenURIContractAddress(address addr)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_tokenURIContractAddress = addr;
	}

	function setProxyRegistryAddress(address addr)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_setProxyRegistryAddress(addr);
	}

	function properties(uint256 tokenId)
		public
		view
		returns (MeemProperties memory)
	{
		return _properties[tokenId];
	}

	function contractURI() public view returns (string memory) {
		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(bytes(_contractURI))
				)
			);
	}

	function childrenOf(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _children[tokenId];
	}

	function numChildrenOf(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		return _children[tokenId].length;
	}

	function setTotalCopies(uint256 tokenId, uint256 newTotalCopies)
		public
		override
	{
		ownsToken(tokenId);

		require(
			newTotalCopies <= numChildrenOf(tokenId),
			'Total copies can not be less than the the existing number of copies'
		);

		require(
			_properties[tokenId].totalCopiesLockedBy == address(0),
			'Total Copies is locked'
		);

		_properties[tokenId].totalCopies = newTotalCopies;
	}

	function lockTotalCopies(uint256 tokenId) public override {
		require(
			_properties[tokenId].totalCopiesLockedBy == address(0),
			'Total Copies is already locked'
		);

		ownsToken(tokenId);

		_properties[tokenId].totalCopiesLockedBy = msg.sender;
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) public override {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);

		perms.push(permission);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) public override {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		removePermissionAtIndex(perms, idx);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) public override {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		perms[idx] = permission;
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) public override {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		require(props.splitsLockedBy == address(0), 'Splits are locked');
		props.splits.push(split);
		validateSplits(tokenId, props.splits);
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) public override {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		require(props.splitsLockedBy == address(0), 'Splits are locked');
		require(
			props.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		if (idx >= props.splits.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < props.splits.length - 1; i++) {
			props.splits[i] = props.splits[i + 1];
		}

		delete props.splits[props.splits.length - 1];
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) public override {
		ownsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		require(props.splitsLockedBy == address(0), 'Splits are locked');
		require(
			props.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		props.splits[idx] = split;
		validateSplits(tokenId, props.splits);
	}

	// Internal functions
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	)
		internal
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
		whenNotPaused
	{
		// Only allow transer if an admin OR if the token parent is from this contract
		require(
			hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
				_parent[tokenId] == address(this),
			'Only Meem copies can be transferred. If you own the original NFT use the claim function instead'
		);

		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		virtual
		override
		returns (bool)
	{
		require(
			_exists(tokenId),
			'ERC721: operator query for nonexistent token'
		);
		address owner = ERC721Upgradeable.ownerOf(tokenId);
		return (spender == owner ||
			hasRole(DEFAULT_ADMIN_ROLE, spender) ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(owner, spender));
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		onlyRole(UPGRADER_ROLE)
	{}

	function _burn(uint256 tokenId)
		internal
		override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
	{
		super._burn(tokenId);
	}

	// function _transfer(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId
	// ) internal virtual override {
	// 	super._transfer(from, to, tokenId);
	// }

	// Private functions
	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		if (propertyType == PropertyType.Meem) {
			return _properties[tokenId];
		} else if (propertyType == PropertyType.Child) {
			return _childProperties[tokenId];
		}

		revert('Invalid property type');
	}

	function getPermissions(
		MeemProperties storage props,
		PermissionType permissionType
	) private view returns (MeemPermission[] storage) {
		if (permissionType == PermissionType.Copy) {
			require(
				props.copyPermissionsLockedBy == address(0),
				'Copy permissions are locked'
			);
			return props.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			require(
				props.remixPermissionsLockedBy == address(0),
				'Remix permissions are locked'
			);
			return props.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			require(
				props.readPermissionsLockedBy == address(0),
				'Read permissions are locked'
			);
			return props.readPermissions;
		}

		revert('Invalid permission type');
	}

	function removePermissionAtIndex(
		MeemPermission[] storage perms,
		uint256 idx
	) private {
		if (idx >= perms.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < perms.length - 1; i++) {
			perms[i] = perms[i + 1];
		}

		delete perms[perms.length - 1];
	}

	function permissionNotLocked(
		MeemProperties storage props,
		PermissionType permissionType
	) private view {
		if (permissionType == PermissionType.Copy) {
			require(
				props.copyPermissionsLockedBy == address(0),
				'Copy permissions are locked'
			);
		} else if (permissionType == PermissionType.Remix) {
			require(
				props.remixPermissionsLockedBy == address(0),
				'Remix permissions are locked'
			);
		} else if (permissionType == PermissionType.Read) {
			require(
				props.readPermissionsLockedBy == address(0),
				'Read permissions are locked'
			);
		}
	}

	function ownsToken(uint256 tokenId) private view {
		require(
			ownerOf(tokenId) == msg.sender ||
				hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
			'Not owner of token'
		);
	}

	function validateSplits(uint256 tokenId, Split[] memory splits)
		private
		view
	{
		// Ensure addresses are unique
		for (uint256 i = 0; i < splits.length; i++) {
			address split1 = splits[i].toAddress;

			for (uint256 j = 0; j < splits.length; j++) {
				address split2 = splits[j].toAddress;
				if (i != j && split1 == split2) {
					revert('Split addresses must be unique');
				}
			}
		}

		uint256 totalAmount = 0;
		uint256 totalAmountOfNonOwner = 0;
		address tokenOwner = ownerOf(tokenId);
		// Require that split amounts
		for (uint256 i = 0; i < splits.length; i++) {
			totalAmount += splits[i].amount;
			if (splits[i].toAddress != tokenOwner) {
				totalAmountOfNonOwner += splits[i].amount;
			}
		}

		require(
			totalAmount <= 10000,
			'Total basis points amount must be less than 10000 (100%)'
		);

		require(
			totalAmountOfNonOwner >= nonOwnerSplitAllocationAmount,
			'Split allocation for non-owner is too low'
		);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) private {
		MeemProperties storage props = getProperties(tokenId, propertyType);

		for (uint256 i = 0; i < mProperties.copyPermissions.length; i++) {
			props.copyPermissions.push(mProperties.copyPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.remixPermissions.length; i++) {
			props.remixPermissions.push(mProperties.remixPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.readPermissions.length; i++) {
			props.readPermissions.push(mProperties.readPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.splits.length; i++) {
			props.splits.push(mProperties.splits[i]);
		}

		props.totalCopies = mProperties.totalCopies;
		props.totalCopiesLockedBy = mProperties.totalCopiesLockedBy;
		props.copyPermissionsLockedBy = mProperties.copyPermissionsLockedBy;
		props.remixPermissionsLockedBy = mProperties.remixPermissionsLockedBy;
		props.readPermissionsLockedBy = mProperties.readPermissionsLockedBy;
		props.splitsLockedBy = mProperties.splitsLockedBy;
	}
}
