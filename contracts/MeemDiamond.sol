// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import './solidstate/proxy/diamond/Diamond.sol';
import './solidstate/token/ERC721/metadata/ERC721MetadataStorage.sol';
import './solidstate/token/ERC721/IERC721.sol';
import './solidstate/introspection/ERC165.sol';

contract MeemDiamond is Diamond {
	using ERC165Storage for ERC165Storage.Layout;

	constructor() {
		// ERC721MetadataStorage.Layout storage erc721 = ERC721MetadataStorage
		// 	.layout();
		// erc721.name = 'Meem';
		// erc721.symbol = 'MEEM';
		// ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
		// erc165.setSupportedInterface(type(IERC721).interfaceId, true);
	}
}
