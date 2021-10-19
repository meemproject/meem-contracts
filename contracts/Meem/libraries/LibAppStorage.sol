// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibMeta} from '../libraries/LibMeta.sol';
import {Meem, Chain} from './MeemStandard.sol';

struct RoleData {
	mapping(address => bool) members;
	bytes32 adminRole;
}

struct AppStorage {
	bytes32 DEFAULT_ADMIN_ROLE;
	bytes32 PAUSER_ROLE;
	bytes32 MINTER_ROLE;
	bytes32 UPGRADER_ROLE;
	uint256 tokenCounter;
	string name;
	string symbol;
	uint32[] tokenIds;
	mapping(address => uint256[]) ownerTokenIds;
	mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
	mapping(uint256 => address) approved;
	mapping(address => mapping(address => bool)) operators;
	mapping(uint256 => Meem) meems;
	uint256 nonOwnerSplitAllocationAmount;
	string contractURI;
	uint256 copyDepth;
	mapping(uint256 => string) tokenURIs;
	mapping(uint256 => uint256[]) children;
	mapping(bytes32 => RoleData) roles;
	// Mapping from token ID to owner address
	mapping(uint256 => address) owners;
	// Mapping owner address to token count
	// mapping(address => uint256) balances;
	// Mapping from token ID to approved address
	mapping(uint256 => address) tokenApprovals;
	// Mapping from owner to operator approvals
	mapping(address => mapping(address => bool)) operatorApprovals;
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
