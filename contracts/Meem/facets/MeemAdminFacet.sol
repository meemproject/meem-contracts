// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {IMeemAdminStandard} from '../interfaces/MeemStandard.sol';
import {InvalidNonOwnerSplitAllocationAmount} from '../libraries/Errors.sol';

contract MeemAdminFacet is IMeemAdminStandard {
	function setTokenCounter(uint256 tokenCounter) public override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		s.tokenCounter = tokenCounter;
	}

	function setContractURI(string memory newContractURI) public override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		s.contractURI = newContractURI;
	}

	function setChildDepth(uint256 newChildDepth) public override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		s.childDepth = newChildDepth;
	}

	function setNonOwnerSplitAllocationAmount(uint256 amount) public override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		if (amount < 0 || amount > 10000) {
			revert InvalidNonOwnerSplitAllocationAmount(0, 10000);
		}

		s.nonOwnerSplitAllocationAmount = amount;
	}
}
