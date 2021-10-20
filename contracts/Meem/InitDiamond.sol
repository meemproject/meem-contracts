// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AppStorage} from './libraries/LibAppStorage.sol';
import {LibAccessControl} from './libraries/LibAccessControl.sol';
import {LibDiamond} from './libraries/LibDiamond.sol';
import {IDiamondCut} from './interfaces/IDiamondCut.sol';
import {IERC165} from './interfaces/IERC165.sol';
import {IDiamondLoupe} from './interfaces/IDiamondLoupe.sol';
import {IERC173} from './interfaces/IERC173.sol';

contract InitDiamond {
	AppStorage internal s;

	struct Args {
		string name;
		string symbol;
		uint256 copyDepth;
		uint256 nonOwnerSplitAllocationAmount;
	}

	function init(Args memory _args) external {
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

		// adding ERC165 data
		ds.supportedInterfaces[type(IERC165).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
		ds.supportedInterfaces[type(IERC173).interfaceId] = true;

		s.name = _args.name;
		s.symbol = _args.symbol;
		s.copyDepth = _args.copyDepth;
		s.nonOwnerSplitAllocationAmount = _args.nonOwnerSplitAllocationAmount;
		s.PAUSER_ROLE = keccak256('PAUSER_ROLE');
		s.MINTER_ROLE = keccak256('MINTER_ROLE');
		s.UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
		s.DEFAULT_ADMIN_ROLE = keccak256('DEFAULT_ADMIN_ROLE');

		LibAccessControl._grantRole(s.PAUSER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.MINTER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.UPGRADER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.DEFAULT_ADMIN_ROLE, msg.sender);
	}
}
