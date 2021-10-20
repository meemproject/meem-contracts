// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AppStorage} from './libraries/LibAppStorage.sol';
import {LibAccessControl} from './libraries/LibAccessControl.sol';
import {LibDiamond} from './libraries/LibDiamond.sol';
import {IDiamondCut} from './interfaces/IDiamondCut.sol';
import {IERC165} from './interfaces/IERC165.sol';
import {IDiamondLoupe} from './interfaces/IDiamondLoupe.sol';
import {IERC173} from './interfaces/IERC173.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import {ERC721URIStorage} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

// import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
// import {ERC721Pausable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';

contract InitDiamond {
	AppStorage internal s;

	struct Args {
		string name;
		string symbol;
		uint256 copyDepth;
		uint256 nonOwnerSplitAllocationAmount;
		address proxyRegistryAddress;
	}

	function init(Args memory _args) external {
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

		// adding ERC165 data
		ds.supportedInterfaces[type(IERC165).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
		ds.supportedInterfaces[type(IERC173).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;
		ds.supportedInterfaces[type(ERC721URIStorage).interfaceId] = true;

		s.proxyRegistryAddress = _args.proxyRegistryAddress;
		s.name = _args.name;
		s.symbol = _args.symbol;
		s.copyDepth = _args.copyDepth;
		s.nonOwnerSplitAllocationAmount = _args.nonOwnerSplitAllocationAmount;
		s.tokenCounter = 0;
		s.PAUSER_ROLE = keccak256('PAUSER_ROLE');
		s.MINTER_ROLE = keccak256('MINTER_ROLE');
		s.UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
		s.DEFAULT_ADMIN_ROLE = keccak256('DEFAULT_ADMIN_ROLE');
		s
			.contractURI = '{"name": "Meem","description": "Meems are pieces of digital content wrapped in more advanced dynamic property rights. They are ideas, stories, images -- existing independently from any social platform -- whose creators have set the terms by which others can access, remix, and share in their value. Join us at https://discord.gg/5NP8PYN8","image": "https://meem-assets.s3.amazonaws.com/meem.jpg","external_link": "https://meem.wtf","seller_fee_basis_points": 1000, "fee_recipient": "0x40c6BeE45d94063c5B05144489cd8A9879899592"}';

		LibAccessControl._grantRole(s.PAUSER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.MINTER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.UPGRADER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.DEFAULT_ADMIN_ROLE, msg.sender);
	}
}
