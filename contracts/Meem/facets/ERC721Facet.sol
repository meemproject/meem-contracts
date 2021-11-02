// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibStrings} from '../libraries/LibStrings.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibMeta} from '../libraries/LibMeta.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Base64} from '../libraries/Base64.sol';
import {IERC721} from '../interfaces/IERC721.sol';
import {ERC721BaseInternal} from '../interfaces/ERC721BaseInternal.sol';
import {IERC721Enumerable} from '@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol';
import {IERC721Metadata} from '@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol';
import {ERC721BaseStorage} from '@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol';

contract ERC721Facet is
	IERC721,
	IERC721Enumerable,
	IERC721Metadata,
	ERC721BaseInternal
{
	function setContractURI(string memory newContractURI) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		s.contractURI = newContractURI;
	}

	function contractURI() public view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
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

	///@notice Return the universal name of the NFT
	function name() public view override returns (string memory) {
		return LibERC721.name();
	}

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() public view override returns (string memory) {
		return LibERC721.symbol();
	}

	function baseTokenURI() public pure returns (string memory) {
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
		return LibERC721.tokenURI(tokenId);
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

	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return LibERC721._exists(tokenId);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		virtual
		override
		returns (bool)
	{
		return LibERC721._isApprovedOrOwner(spender, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function getApproved(uint256 tokenId)
		public
		view
		override
		returns (address)
	{
		return _getApproved(tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function isApprovedForAll(address account, address operator)
		public
		view
		override
		returns (bool)
	{
		return LibERC721.isApprovedForAll(account, operator);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override {
		return LibERC721.transferFrom(from, to, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override {
		return LibERC721.safeTransferFrom(from, to, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public payable override {
		return LibERC721._safeTransfer(from, to, tokenId, data);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function approve(address operator, uint256 tokenId)
		public
		payable
		override
	{
		return LibERC721.approve(operator, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function setApprovalForAll(address operator, bool status) public override {
		return LibERC721.setApprovalForAll(operator, status);
	}

	/**
	 * @notice ERC721 hook: revert if value is included in external approve function call
	 * @inheritdoc ERC721BaseInternal
	 */
	function _handleApproveMessageValue(
		address operator,
		uint256 tokenId,
		uint256 value
	) internal virtual override {
		return LibERC721._handleApproveMessageValue(operator, tokenId, value);
	}

	/**
	 * @notice ERC721 hook: revert if value is included in external transfer function call
	 * @inheritdoc ERC721BaseInternal
	 */
	function _handleTransferMessageValue(
		address from,
		address to,
		uint256 tokenId,
		uint256 value
	) internal virtual override {
		return LibERC721._handleTransferMessageValue(from, to, tokenId, value);
	}
}
