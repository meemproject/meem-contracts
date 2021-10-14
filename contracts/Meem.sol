// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
	event InviterSet(uint256 tokenId, address inviter);

	using CountersUpgradeable for CountersUpgradeable.Counter;
	using StringsUpgradeable for uint256;

	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
	bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

	CountersUpgradeable.Counter private _tokenIdCounter;

	// Mapping from token ID to inviter address
	mapping(uint256 => address) private _inviters;
	address private _tokenURIContractAddress;
	string private _contractURI;

	mapping(uint256 => Permission) private _copyPermission;
	mapping(uint256 => Permission) private _remixPermission;
	mapping(uint256 => Permission) private _readPermission;
	mapping(uint256 => address[]) private _copyPermissionAddresses;
	mapping(uint256 => address[]) private _remixPermissionAddresses;
	mapping(uint256 => address[]) private _readPermissionAddresses;
	mapping(uint256 => uint256[]) private _copyPermissionNumTokens;
	mapping(uint256 => uint256[]) private _remixPermissionNumTokens;
	mapping(uint256 => uint256[]) private _readPermissionNumTokens;
	mapping(uint256 => address) private _copyLockedBy;
	mapping(uint256 => address) private _remixLockedBy;
	mapping(uint256 => address) private _readLockedBy;
	mapping(uint256 => Chain) private _chain;
	mapping(uint256 => address) private _parent;
	mapping(uint256 => uint256) private _parentTokenId;
	mapping(uint256 => address[]) private _splitAddresses;
	mapping(uint256 => uint256[]) private _splitAmounts;
	mapping(uint256 => address[]) private _splitLockedBy;
	mapping(uint256 => string) private _tokenURIs;
	mapping(uint256 => uint256) private _totalCopies;

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

	// function mint(address to) public onlyRole(MINTER_ROLE) {
	// 	_safeMint(to, _tokenIdCounter.current());
	// 	_inviters[_tokenIdCounter.current()] = msg.sender;
	// 	emit InviterSet(_tokenIdCounter.current(), msg.sender);
	// 	_tokenIdCounter.increment();
	// }

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
	) public override onlyRole(MINTER_ROLE) {
		uint256 tokenId = _tokenIdCounter.current();
		_safeMint(mTo, tokenId);
		_tokenURIs[tokenId] = mTokenURI;
		_chain[tokenId] = mChain;
		_parent[tokenId] = mParent;
		_parentTokenId[tokenId] = mParentTokenId;
		require(
			mCopyRemixReadPermission.length == 3,
			'All permissions must be set.'
		);
		_copyPermission[tokenId] = mCopyRemixReadPermission[0];
		_remixPermission[tokenId] = mCopyRemixReadPermission[1];
		_readPermission[tokenId] = mCopyRemixReadPermission[2];
		_copyPermissionAddresses[tokenId] = mCopyPermissionAddresses;
		_remixPermissionAddresses[tokenId] = mRemixPermissionAddresses;
		_readPermissionAddresses[tokenId] = mReadPermissionAddresses;
		require(
			mCopyRemixReadLockedByAddress.length == 3,
			"All permissions 'locked by' must be set"
		);
		_copyLockedBy[tokenId] = mCopyRemixReadLockedByAddress[0];
		_remixLockedBy[tokenId] = mCopyRemixReadLockedByAddress[1];
		_readLockedBy[tokenId] = mCopyRemixReadLockedByAddress[2];
		// _splitAddresses[tokenId] = mSplitAddresses;
		// _splitAmounts[tokenId] = mSplitAmounts;
		// _totalCopies[tokenId] = mTotalCopies;
		setSplits(tokenId, mSplitAddresses, mSplitAmounts);
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

	/** The total number of copies allowed for a Meem */
	// function totalCopies(uint256 tokenId) external view returns (uint256);

	// function setTotalCopies(uint256 numCopies) external;

	/** The address of the parent contract NFT */
	function parent(uint256 tokenId) public view override returns (address) {
		return _parent[tokenId];
	}

	/** The tokenId of the parent contract NFT */
	function parentTokenId(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		return _parentTokenId[tokenId];
	}

	/** The chain of the parent contract NFT  */
	function parentChain(uint256 tokenId) public view override returns (Chain) {
		return _chain[tokenId];
	}

	function copyPermission(uint256 tokenId)
		public
		view
		override
		returns (Permission)
	{
		return _copyPermission[tokenId];
	}

	function remixPermission(uint256 tokenId)
		public
		view
		override
		returns (Permission)
	{
		return _remixPermission[tokenId];
	}

	function readPermission(uint256 tokenId)
		public
		view
		override
		returns (Permission)
	{
		return _readPermission[tokenId];
	}

	function copyPermissionAddresses(uint256 tokenId)
		public
		view
		override
		returns (address[] memory)
	{
		return _copyPermissionAddresses[tokenId];
	}

	function remixPermissionAddresses(uint256 tokenId)
		public
		view
		override
		returns (address[] memory)
	{
		return _remixPermissionAddresses[tokenId];
	}

	function readPermissionAddresses(uint256 tokenId)
		public
		view
		override
		returns (address[] memory)
	{
		return _readPermissionAddresses[tokenId];
	}

	function copyPermissionNumTokens(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _copyPermissionNumTokens[tokenId];
	}

	function remixPermissionNumTokens(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _remixPermissionNumTokens[tokenId];
	}

	function readPermissionNumTokens(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _readPermissionNumTokens[tokenId];
	}

	function numSplits(uint256 tokenId) public view override returns (uint256) {
		return _splitAddresses[tokenId].length;
	}

	function splitAddresses(uint256 tokenId)
		public
		view
		override
		returns (address[] memory)
	{
		return _splitAddresses[tokenId];
	}

	function splitAmounts(uint256 tokenId)
		public
		view
		override
		returns (uint256[] memory)
	{
		return _splitAmounts[tokenId];
	}

	function splitLockedBy(uint256 tokenId)
		public
		view
		override
		returns (address[] memory)
	{
		return _splitLockedBy[tokenId];
	}

	// Internal functions
	function _baseURI() internal pure override returns (string memory) {
		return 'https://meem.wtf/';
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	)
		internal
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
		whenNotPaused
	{
		super._beforeTokenTransfer(from, to, tokenId);
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

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._transfer(from, to, tokenId);

		// Since the token was transferred, the inviter of the token becomes the from address
		_inviters[tokenId] = from;

		emit InviterSet(tokenId, from);
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

	// Private functions
	function setSplits(
		uint256 tokenId,
		address[] memory mSplitAddresses,
		uint256[] memory mSplitAmounts
	) private {
		require(
			mSplitAddresses.length == mSplitAmounts.length,
			'Split addresses and amounts length must match'
		);
		uint256 totalAmount = 0;
		address tokenOwner = ownerOf(tokenId);
		// Require that split amounts
		for (uint256 i = 0; i < mSplitAddresses.length; i++) {
			totalAmount += mSplitAmounts[i];
			require(
				mSplitAddresses[i] != tokenOwner,
				'Splits can not be assigned to token owner'
			);
		}

		require(
			totalAmount <= 10000,
			'Total basis points amount must be less than 10000 (100%)'
		);

		_splitAddresses[tokenId] = mSplitAddresses;
		_splitAmounts[tokenId] = mSplitAmounts;
	}
}
