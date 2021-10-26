// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
// import '@openzeppelin/contracts/access/Ownable.sol';
// import {ERC721} from '../common/solidstate/token/ERC721/ERC721.sol';
import {ERC721MetadataStorage} from '../common/solidstate/token/ERC721/metadata/ERC721MetadataStorage.sol';
import {Ownable} from '../common/solidstate/access/Ownable.sol';
import {ERC721Storage} from '../libraries/ERC721Storage.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './meta-transactions/ContentMixin.sol';
import './meta-transactions/NativeMetaTransaction.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
	ContextMixin,
	ERC721Enumerable,
	NativeMetaTransaction,
	Ownable
{
	using SafeMath for uint256;

	// address proxyRegistryAddress;
	// uint256 private _currentTokenId = 0;

	constructor(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress
	) ERC721(_name, _symbol) {
		ERC721Storage.Layout storage l = ERC721Storage.layout();
		l.proxyRegistryAddress = _proxyRegistryAddress;
		_initializeEIP712(_name);
	}

	function name() public view override returns (string memory) {
		ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
		return l.name;
	}

	function symbol() public view override returns (string memory) {
		ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
		return l.symbol;
	}

	function baseTokenURI() public pure virtual returns (string memory);

	function tokenURI(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
			);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ERC721Storage.Layout storage l = ERC721Storage.layout();
		ProxyRegistry proxyRegistry = ProxyRegistry(
			address(l.proxyRegistryAddress)
		);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	/**
	 * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
	 */
	function _msgSender() internal view override returns (address sender) {
		return ContextMixin.msgSender();
	}
}
