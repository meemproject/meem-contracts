// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721Storage {
	bytes32 internal constant STORAGE_SLOT =
		keccak256('meemproject.storage.ERC721');

	struct Layout {
		address proxyRegistryAddress;
	}

	function layout() internal pure returns (Layout storage l) {
		bytes32 slot = STORAGE_SLOT;
		assembly {
			l.slot := slot
		}
	}
}
