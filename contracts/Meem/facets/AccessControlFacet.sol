// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';

contract AccessControlFacet {
	function DEFAULT_ADMIN_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.DEFAULT_ADMIN_ROLE;
	}

	function PAUSER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.PAUSER_ROLE;
	}

	function MINTER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.MINTER_ROLE;
	}

	function UPGRADER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.UPGRADER_ROLE;
	}

	function grantRole(address user, bytes32 role) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		LibAccessControl._grantRole(role, user);
	}

	function revokeRole(address user, bytes32 role) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		LibAccessControl._revokeRole(role, user);
	}
}
