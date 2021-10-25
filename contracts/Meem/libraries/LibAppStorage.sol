// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibMeta} from '../libraries/LibMeta.sol';
import {Meem, Chain} from '../interfaces/MeemStandard.sol';

struct RoleData {
	mapping(address => bool) members;
	bytes32 adminRole;
}

struct AppStorage {
	address proxyRegistryAddress;
	/** AccessControl Role: Admin */
	bytes32 DEFAULT_ADMIN_ROLE;
	/** AccessControl Role: Pauser */
	bytes32 PAUSER_ROLE;
	/** AccessControl Role: Minter */
	bytes32 MINTER_ROLE;
	/** AccessControl Role: Upgrader */
	bytes32 UPGRADER_ROLE;
	/** Counter of next incremental token */
	uint256 tokenCounter;
	/** ERC721 Name */
	string name;
	/** ERC721 Symbol */
	string symbol;
	// uint32[] tokenIds;
	/** Mapping of addresses => all tokens they own */
	mapping(address => uint256[]) ownerTokenIds;
	/** Mapping of addresses => number of tokens owned */
	mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
	/** Mapping of token to approved address */
	mapping(uint256 => address) approved;
	/** Mapping of address to operators */
	mapping(address => mapping(address => bool)) operators;
	/** Mapping of token => Meem data  */
	mapping(uint256 => Meem) meems;
	/** The minimum amount that must be allocated to non-owners of a token in splits */
	uint256 nonOwnerSplitAllocationAmount;
	/** The contract URI. Used to describe this NFT collection */
	string contractURI;
	/** The depth allowed for minting of children. If 0, no child copies are allowed. */
	uint256 childDepth;
	/** Mapping of token => URIs for each token */
	mapping(uint256 => string) tokenURIs;
	/** Mapping of token to all children */
	mapping(uint256 => uint256[]) children;
	/** Mapping of token to all decendants */
	mapping(uint256 => uint256[]) decendants;
	/** Keeps track of assigned roles */
	mapping(bytes32 => RoleData) roles;
	/** Mapping from token ID to owner address */
	// mapping(uint256 => address) owners;
	// Mapping owner address to token count
	// mapping(address => uint256) balances;

	/** Mapping from token ID to approved address */
	mapping(uint256 => address) tokenApprovals;
	/** Mapping from owner to operator approvals */
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
