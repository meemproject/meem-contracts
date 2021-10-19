// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {LibDiamond} from '../../shared/libraries/LibDiamond.sol';
import {LibMeta} from '../../shared/libraries/LibMeta.sol';
import {Meem, Chain} from './MeemStandard.sol';

struct AppStorage {
	string name;
	string symbol;
	uint32[] tokenIds;
	mapping(address => uint32[]) ownerTokenIds;
	mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
	mapping(uint256 => address) approved;
	mapping(address => mapping(address => bool)) operators;
	mapping(uint256 => Meem) meems;
	uint256 nonOwnerSplitAllocationAmount;
}

library LibAppStorage {
	function diamondStorage() internal pure returns (AppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}

	function abs(int256 x) internal pure returns (uint256) {
		return uint256(x >= 0 ? x : -x);
	}
}

contract Modifiers {
	AppStorage internal s;
	modifier onlyTokenOwner(uint256 _tokenId) {
		require(
			LibMeta.msgSender() == s.meems[_tokenId].owner,
			'LibAppStorage: Only aavegotchi owner can call this function'
		);
		_;
	}

	modifier onlyContractOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}
}
