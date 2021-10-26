// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibStrings} from '../libraries/LibStrings.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {AppStorage, LibAppStorage} from '../libraries/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibMeta} from '../libraries/LibMeta.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Base64} from '../libraries/Base64.sol';
import {ERC721Tradable, ProxyRegistry} from '../../common/ERC721Tradable.sol';

contract ERC721Facet is ERC721Tradable {
	constructor() ERC721Tradable('Meem', 'MEEM', address(0)) {}

	function contractURI() public view returns (string memory) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(bytes(s.contractURI))
				)
			);
	}

	function contractAddress() public view returns (address) {
		return address(this);
	}

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() public view override returns (uint256 totalSupply_) {
		return LibERC721.totalSupply();
	}

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return tokenId_ The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index)
		public
		view
		override
		returns (uint256 tokenId_)
	{
		return LibERC721.tokenByIndex(_index);
	}

	function ownerOf(uint256 tokenId) public view override returns (address) {
		return LibERC721.ownerOf(tokenId);
	}

	function balanceOf(address _owner)
		public
		view
		override
		returns (uint256 balance)
	{
		return LibERC721.balanceOf(_owner);
	}

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return tokenId_ The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		public
		view
		override
		returns (uint256 tokenId_)
	{
		return LibERC721.tokenOfOwnerByIndex(_owner, _index);
	}

	// @notice Transfers the ownership of multiple  NFTs from one address to another at once
	/// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
	///  operator, or the approved address of each of the NFTs in `_tokenIds`. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if one of the NFTs in
	///  `_tokenIds` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFTs
	/// @param _to The new owner
	/// @param _tokenIds An array containing the identifiers of the NFTs to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeBatchTransferFrom(
		address _from,
		address _to,
		uint256[] calldata _tokenIds,
		bytes calldata _data
	) external {
		address sender = LibMeta.msgSender();
		for (uint256 index = 0; index < _tokenIds.length; index++) {
			uint256 _tokenId = _tokenIds[index];
			internalTransferFrom(sender, _from, _to, _tokenId);
			LibERC721._checkOnERC721Received(
				sender,
				_from,
				_to,
				_tokenId,
				_data
			);
		}
	}

	///@notice Return the universal name of the NFT
	function name() public view override returns (string memory) {
		return LibERC721.name();
	}

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() public view override returns (string memory) {
		return LibERC721.symbol();
	}

	function baseTokenURI() public pure override returns (string memory) {
		return LibERC721.baseTokenURI();
	}

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.tokenURIs[tokenId];
	}

	function isApprovedForAll(address _owner, address operator)
		public
		view
		virtual
		override(ERC721Tradable)
		returns (bool)
	{
		AppStorage storage s = LibAppStorage.diamondStorage();
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(s.proxyRegistryAddress);
		if (address(proxyRegistry.proxies(_owner)) == operator) {
			return true;
		}

		return false;
	}

	function transferOwnership(address _newOwner) public override {
		LibDiamond.enforceIsContractOwner();
		LibDiamond.setContractOwner(_newOwner);
	}

	function owner() public view override returns (address owner_) {
		owner_ = LibDiamond.contractOwner();
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {}

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal override {
		LibERC721._transfer(from, to, tokenId);
	}

	function internalTransferFrom(
		address _sender,
		address _from,
		address _to,
		uint256 _tokenId
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(_to != address(0), "ERC721Facet: Can't transfer to 0 address");
		require(_from != address(0), "ERC721Facet: _from can't be 0 address");
		require(
			_from == s.meems[_tokenId].owner,
			'ERC721Facet: _from is not owner, transfer failed'
		);
		require(
			_sender == _from ||
				s.operators[_from][_sender] ||
				_sender == s.approved[_tokenId],
			'ERC721Facet: Not owner or approved to transfer'
		);
		LibMeem.transfer(_from, _to, _tokenId);
		// LibERC721Marketplace.updateERC721Listing(
		// 	address(this),
		// 	_tokenId,
		// 	_from
		// );
	}

	function _exists(uint256 tokenId)
		internal
		view
		virtual
		override
		returns (bool)
	{
		return LibERC721._exists(tokenId);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		virtual
		override
		returns (bool)
	{
		require(
			_exists(tokenId),
			'ERC721: operator query for nonexistent token'
		);
		address _owner = ownerOf(tokenId);
		return (spender == _owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(_owner, spender));
	}
}
