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
import './MeemProps.sol';

contract Meem is
	ERC721TradableUpgradeable,
	AccessControlUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	UUPSUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721EnumerableUpgradeable,
	ERC721URIStorageUpgradeable,
	MeemStandard,
	MeemProps
{
	using CountersUpgradeable for CountersUpgradeable.Counter;
	using StringsUpgradeable for uint256;

	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
	bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

	CountersUpgradeable.Counter private _tokenIdCounter;

	address private _tokenURIContractAddress;
	string private _contractURI;
	uint256 private _copyDepth;
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

		_copyDepth = 1;
		_nonOwnerSplitAllocationAmount = 1000;
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
			ERC721EnumerableUpgradeable,
			MeemProps
		)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	/** Mint a Meem */
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
			'Only Meem copies can be transferred.'
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
}
