// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from './storage/LibAppStorage.sol';
import {LibAccessControl} from './libraries/LibAccessControl.sol';
// import {LibDiamond} from './libraries/LibDiamond.sol';
import {IDiamondCut} from './interfaces/IDiamondCut.sol';
// import {IERC165} from './interfaces/IERC165.sol';
import {IDiamondLoupe} from './interfaces/IDiamondLoupe.sol';
// import {IERC173} from './interfaces/IERC173.sol';
import {IRoyaltiesProvider} from '../royalties/IRoyaltiesProvider.sol';
import {IMeemStandard} from './interfaces/MeemStandard.sol';
// import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
// import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
// import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
// import {ERC721URIStorage} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

import '@solidstate/contracts/introspection/ERC165.sol';
import '@solidstate/contracts/token/ERC721/IERC721.sol';
import '@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol';
import '@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol';
import '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';

contract InitDiamond {
	using ERC165Storage for ERC165Storage.Layout;

	struct Args {
		string name;
		string symbol;
		uint256 childDepth;
		uint256 nonOwnerSplitAllocationAmount;
		address proxyRegistryAddress;
		string contractURI;
	}

	function init(Args memory _args) external {
		// LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

		// // adding ERC165 data
		// ds.supportedInterfaces[type(IERC165).interfaceId] = true;
		// ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
		// ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
		// ds.supportedInterfaces[type(IERC173).interfaceId] = true;
		// ds.supportedInterfaces[type(IERC721).interfaceId] = true;
		// ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		// ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;
		// ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;
		// ds.supportedInterfaces[type(ERC721URIStorage).interfaceId] = true;
		// ds.supportedInterfaces[type(IRoyaltiesProvider).interfaceId] = true;
		// ds.supportedInterfaces[type(IMeemStandard).interfaceId] = true;

		ERC721MetadataStorage.Layout storage erc721 = ERC721MetadataStorage
			.layout();
		erc721.name = 'Meem';
		erc721.symbol = 'MEEM';

		ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
		erc165.setSupportedInterface(type(IERC721).interfaceId, true);
		erc165.setSupportedInterface(type(IDiamondCut).interfaceId, true);
		erc165.setSupportedInterface(type(IDiamondLoupe).interfaceId, true);
		erc165.setSupportedInterface(type(IERC721Metadata).interfaceId, true);
		erc165.setSupportedInterface(type(IERC721Enumerable).interfaceId, true);
		erc165.setSupportedInterface(type(IERC721Enumerable).interfaceId, true);
		erc165.setSupportedInterface(
			type(IRoyaltiesProvider).interfaceId,
			true
		);
		erc165.setSupportedInterface(type(IMeemStandard).interfaceId, true);

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.proxyRegistryAddress = _args.proxyRegistryAddress;
		s.name = _args.name;
		s.symbol = _args.symbol;
		s.childDepth = _args.childDepth;
		s.nonOwnerSplitAllocationAmount = _args.nonOwnerSplitAllocationAmount;
		s.tokenCounter = 0;
		s.PAUSER_ROLE = keccak256('PAUSER_ROLE');
		s.MINTER_ROLE = keccak256('MINTER_ROLE');
		s.UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
		s.DEFAULT_ADMIN_ROLE = keccak256('DEFAULT_ADMIN_ROLE');
		s.contractURI = _args.contractURI;

		LibAccessControl._grantRole(s.PAUSER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.MINTER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.UPGRADER_ROLE, msg.sender);
		LibAccessControl._grantRole(s.DEFAULT_ADMIN_ROLE, msg.sender);
	}
}
