// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';

/// @title Role-based access control for limiting access to some functions of the contract
/// @notice Assign roles to grant access to otherwise limited functions of the contract
contract AccessControlFacet {
	/// @notice An admin of the contract.
	/// @return Hashed value that represents this role.
	function DEFAULT_ADMIN_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.DEFAULT_ADMIN_ROLE;
	}

	/// @notice Can pause interaction with the contract
	/// @return Hashed value that represents this role.
	function PAUSER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.PAUSER_ROLE;
	}

	/// @notice Can mint root level Meems
	/// @return Hashed value that represents this role.
	function MINTER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.MINTER_ROLE;
	}

	/// @notice Can upgrade the contract (currently unused in favor of contract Owner)
	/// @return Hashed value that represents this role.
	function UPGRADER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.UPGRADER_ROLE;
	}

	/// @notice Grant a role to a user. The granting user must have the DEFAULT_ADMIN_ROLE
	/// @param user The wallet address of the user to grant the role to
	/// @param role The role to grant
	function grantRole(address user, bytes32 role) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		LibAccessControl._grantRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the DEFAULT_ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function revokeRole(address user, bytes32 role) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		LibAccessControl._revokeRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the DEFAULT_ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function hasrole(address user, bytes32 role) public view returns (bool) {
		return LibAccessControl.hasRole(role, user);
	}
}
