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
	// constructor() ERC721Tradable('Meem', 'MEEM', address(0)) {
	// 	// _name = name_;
	// 	// _symbol = symbol_;
	// }

	// function onERC721Received(
	// 	address _operator,
	// 	address _from,
	// 	uint256 _tokenId,
	// 	bytes calldata _data
	// ) public override returns (bytes4) {}

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
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.tokenURIs[tokenId];
	}

	// function isApprovedForAll(address _owner, address operator)
	// 	public
	// 	view
	// 	virtual
	// 	returns (bool)
	// {
	// 	LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
	// 	// Whitelist OpenSea proxy contract for easy trading.
	// 	ProxyRegistry proxyRegistry = ProxyRegistry(s.proxyRegistryAddress);
	// 	if (address(proxyRegistry.proxies(_owner)) == operator) {
	// 		return true;
	// 	}

	// 	return false;
	// }

	// function transferOwnership(address _newOwner) public override {
	// 	LibDiamond.enforceIsContractOwner();
	// 	LibDiamond.setContractOwner(_newOwner);
	// }

	// function owner() public view override returns (address owner_) {
	// 	owner_ = LibDiamond.contractOwner();
	// }

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
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
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
		require(
			_exists(tokenId),
			'ERC721: operator query for nonexistent token'
		);
		address _owner = ownerOf(tokenId);
		return (spender == _owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(_owner, spender));
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
		return _isApprovedForAll(account, operator);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override {
		_handleTransferMessageValue(from, to, tokenId, msg.value);
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'ERC721: transfer caller is not owner or approved'
		);
		_transfer(from, to, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override {
		safeTransferFrom(from, to, tokenId, '');
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
		_handleTransferMessageValue(from, to, tokenId, msg.value);
		require(
			_isApprovedOrOwner(msg.sender, tokenId),
			'ERC721: transfer caller is not owner or approved'
		);
		_safeTransfer(from, to, tokenId, data);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function approve(address operator, uint256 tokenId)
		public
		payable
		override
	{
		_handleApproveMessageValue(operator, tokenId, msg.value);
		address owner = ownerOf(tokenId);
		require(operator != owner, 'ERC721: approval to current owner');
		require(
			msg.sender == owner || isApprovedForAll(owner, msg.sender),
			'ERC721: approve caller is not owner nor approved for all'
		);
		_approve(operator, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function setApprovalForAll(address operator, bool status) public override {
		require(operator != msg.sender, 'ERC721: approve to caller');
		ERC721BaseStorage.layout().operatorApprovals[msg.sender][
			operator
		] = status;
		emit ApprovalForAll(msg.sender, operator, status);
	}

	/**
	 * @notice ERC721 hook: revert if value is included in external approve function call
	 * @inheritdoc ERC721BaseInternal
	 */
	function _handleApproveMessageValue(
		address,
		uint256,
		uint256 value
	) internal virtual override {
		require(value == 0, 'ERC721: payable approve calls not supported');
	}

	/**
	 * @notice ERC721 hook: revert if value is included in external transfer function call
	 * @inheritdoc ERC721BaseInternal
	 */
	function _handleTransferMessageValue(
		address,
		address,
		uint256,
		uint256 value
	) internal virtual override {
		require(value == 0, 'ERC721: payable transfer calls not supported');
	}
}
