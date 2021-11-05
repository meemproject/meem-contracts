// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from './storage/LibAppStorage.sol';
import {LibAccessControl} from './libraries/LibAccessControl.sol';
import {IDiamondCut} from './interfaces/IDiamondCut.sol';
import {IDiamondLoupe} from './interfaces/IDiamondLoupe.sol';
import {IRoyaltiesProvider} from '../royalties/IRoyaltiesProvider.sol';
import {IMeemBaseStandard, IMeemSplitsStandard, IMeemPermissionsStandard} from './interfaces/MeemStandard.sol';

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
		erc165.setSupportedInterface(type(IMeemBaseStandard).interfaceId, true);
		erc165.setSupportedInterface(
			type(IMeemSplitsStandard).interfaceId,
			true
		);
		erc165.setSupportedInterface(
			type(IMeemPermissionsStandard).interfaceId,
			true
		);

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.proxyRegistryAddress = _args.proxyRegistryAddress;
		s.name = _args.name;
		s.symbol = _args.symbol;
		s.childDepth = _args.childDepth;
		s.nonOwnerSplitAllocationAmount = _args.nonOwnerSplitAllocationAmount;
		s.tokenCounter = 100000;
		s.ADMIN_ROLE = keccak256('ADMIN_ROLE');
		s.MINTER_ROLE = keccak256('MINTER_ROLE');
		s.contractURI = _args.contractURI;

		LibAccessControl._grantRole(s.ADMIN_ROLE, msg.sender);
		LibAccessControl._grantRole(s.MINTER_ROLE, msg.sender);
	}
}
