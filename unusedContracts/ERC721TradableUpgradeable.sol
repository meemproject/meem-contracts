// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721TradableUpgradeable is Initializable, ERC721Upgradeable {
	address proxyRegistryAddress;

	function __ERC721Tradable_init(
		string memory name_,
		string memory symbol_,
		address _proxyRegistryAddress
	) internal initializer {
		__Context_init_unchained();
		__ERC165_init_unchained();
		__ERC721_init_unchained(name_, symbol_);
		__ERC721Tradable_init_unchained(_proxyRegistryAddress);
	}

	function __ERC721Tradable_init_unchained(address _proxyRegistryAddress)
		internal
		initializer
	{
		proxyRegistryAddress = _proxyRegistryAddress;
	}

	function _setProxyRegistryAddress(address _proxyRegistryAddress) internal {
		proxyRegistryAddress = _proxyRegistryAddress;
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}
}
