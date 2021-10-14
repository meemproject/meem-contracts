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
	mapping(uint256 => MeemProperties) private _properties;
	mapping(uint256 => string) private _tokenURIs;

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
		MeemProperties memory mProperties
	) public override onlyRole(MINTER_ROLE) {
		uint256 tokenId = _tokenIdCounter.current();
		_safeMint(to, tokenId);
		_tokenURIs[tokenId] = mTokenURI;
		validateSplits(tokenId, mProperties.splits);

		// Initializes mapping w/ default values
		delete _properties[tokenId];

		for (uint256 i = 0; i < mProperties.copyPermissions.length; i++) {
			_properties[tokenId].copyPermissions.push(
				mProperties.copyPermissions[i]
			);
		}

		for (uint256 i = 0; i < mProperties.remixPermissions.length; i++) {
			_properties[tokenId].remixPermissions.push(
				mProperties.remixPermissions[i]
			);
		}

		for (uint256 i = 0; i < mProperties.readPermissions.length; i++) {
			_properties[tokenId].readPermissions.push(
				mProperties.readPermissions[i]
			);
		}

		for (uint256 i = 0; i < mProperties.splits.length; i++) {
			_properties[tokenId].splits.push(mProperties.splits[i]);
		}

		_properties[tokenId].chain = mProperties.chain;
		_properties[tokenId].parent = mProperties.parent;
		_properties[tokenId].parentTokenId = mProperties.parentTokenId;
		_properties[tokenId].totalCopies = mProperties.totalCopies;
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
	function validateSplits(uint256 tokenId, Split[] memory splits)
		private
		view
	{
		uint256 totalAmount = 0;
		address tokenOwner = ownerOf(tokenId);
		// Require that split amounts
		for (uint256 i = 0; i < splits.length; i++) {
			totalAmount += splits[i].amount;
			require(
				splits[i].toAddress != tokenOwner,
				'Splits can not be assigned to token owner'
			);
		}

		require(
			totalAmount <= 10000,
			'Total basis points amount must be less than 10000 (100%)'
		);
	}
}
