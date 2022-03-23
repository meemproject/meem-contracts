// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibMeem} from '../libraries/LibMeem.sol';
import {IClippingStandard} from '../interfaces/MeemStandard.sol';

contract ClippingFacet is IClippingStandard {
	function clip(uint256 tokenId) external override {
		return LibMeem.clip(tokenId);
	}

	function unClip(uint256 tokenId) external override {
		return LibMeem.unClip(tokenId);
	}

	function clippings(uint256 tokenId)
		external
		view
		override
		returns (address[] memory)
	{
		return LibMeem.clippings(tokenId);
	}

	function addressClippings(address addy)
		external
		view
		override
		returns (uint256[] memory)
	{
		return LibMeem.addressClippings(addy);
	}

	function hasAddressClipped(uint256 tokenId, address addy)
		external
		view
		override
		returns (bool)
	{
		return LibMeem.hasAddressClipped(tokenId, addy);
	}

	function numClippings(uint256 tokenId)
		external
		view
		override
		returns (uint256)
	{
		return LibMeem.numClippings(tokenId);
	}
}
