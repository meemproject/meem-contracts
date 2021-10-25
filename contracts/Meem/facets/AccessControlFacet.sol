// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AppStorage, LibAppStorage} from '../libraries/LibAppStorage.sol';

contract AccessControlFacet {
	function DEFAULT_ADMIN_ROLE() public view returns (bytes32) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.DEFAULT_ADMIN_ROLE;
	}

	function PAUSER_ROLE() public view returns (bytes32) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.PAUSER_ROLE;
	}

	function MINTER_ROLE() public view returns (bytes32) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.MINTER_ROLE;
	}

	function UPGRADER_ROLE() public view returns (bytes32) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.UPGRADER_ROLE;
	}
}
