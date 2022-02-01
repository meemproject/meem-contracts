// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibArray} from '../libraries/LibArray.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, MeemType} from '../interfaces/MeemStandard.sol';
import {NotTokenOwner, InvalidZeroAddressQuery, IndexOutOfRange, TokenNotFound, NotApproved, NoApproveSelf, ERC721ReceiverNotImplemented, TokenAlreadyExists, ToAddressInvalid, NoTransferWrappedNFT, MeemNotVerified, NotTokenAdmin} from '../libraries/Errors.sol';
import '../interfaces/IERC721TokenReceiver.sol';

library LibERC721 {
	/**
	 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
	 */
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
	 */
	event Approval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	 */
	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	function requireOwnsToken(uint256 tokenId) internal view {
		if (ownerOf(tokenId) != msg.sender) {
			revert NotTokenOwner(tokenId);
		}
	}

	function burn(uint256 tokenId) internal {
		requireOwnsToken(tokenId);

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = ownerOf(tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		// Make zero address new owner
		uint256 index = s.ownerTokenIdIndexes[owner][tokenId];
		s.ownerTokenIds[owner] = LibArray.removeAt(
			s.ownerTokenIds[owner],
			index
		);
		delete s.ownerTokenIdIndexes[owner][tokenId];

		s.ownerTokenIds[address(0)].push(tokenId);
		s.ownerTokenIdIndexes[address(0)][tokenId] =
			s.ownerTokenIds[address(0)].length -
			1;

		emit Transfer(owner, address(0), tokenId);
	}

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.allTokens.length;
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (owner == address(0)) {
			revert InvalidZeroAddressQuery();
		}
		return s.ownerTokenIds[owner].length;
	}

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return tokenId_ The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index)
		internal
		view
		returns (uint256 tokenId_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (_index >= s.allTokens.length) {
			revert IndexOutOfRange(_index, s.allTokens.length - 1);
		}
		tokenId_ = s.allTokens[_index];
	}

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return tokenId_ The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		internal
		view
		returns (uint256 tokenId_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (_index >= s.ownerTokenIds[_owner].length) {
			revert IndexOutOfRange(_index, s.ownerTokenIds[_owner].length - 1);
		}
		tokenId_ = s.ownerTokenIds[_owner][_index];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) internal view returns (address) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = s.meems[tokenId].owner;
		if (owner == address(0)) {
			revert TokenNotFound(tokenId);
		}
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.symbol;
	}

	function tokenURI(uint256 tokenId) internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!_exists(tokenId)) {
			revert TokenNotFound(tokenId);
		}

		return s.tokenURIs[tokenId];
	}

	/**
	 * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
	 * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
	 * by default, can be overriden in child contracts.
	 */
	function _baseURI() internal pure returns (string memory) {
		return '';
	}

	function baseTokenURI() internal pure returns (string memory) {
		return 'https://meem.wtf/tokens/';
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) internal {
		address owner = ownerOf(tokenId);

		if (to == owner) {
			revert NoApproveSelf();
		}

		if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
			revert NotApproved();
		}

		_approve(to, tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) internal view returns (address) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!_exists(tokenId)) {
			revert TokenNotFound(tokenId);
		}

		return s.tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (operator == _msgSender()) {
			revert NoApproveSelf();
		}

		s.operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address owner, address operator)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.operatorApprovals[owner][operator];
	}

	// /**
	//  * @dev See {IERC721-transferFrom}.
	//  */
	// function transferFrom(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId
	// ) internal {
	// 	if (
	// 		// !_isApprovedOrOwner(_msgSender(), tokenId) &&
	// 		!_canFacilitateClaim(_msgSender(), tokenId)
	// 	) {
	// 		revert NotApproved();
	// 	}

	// 	_transfer(from, to, tokenId);
	// }

	// /**
	//  * @dev See {IERC721-safeTransferFrom}.
	//  */
	// function safeTransferFrom(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId
	// ) internal {
	// 	safeTransferFrom(from, to, tokenId, '');
	// }

	// /**
	//  * @dev See {IERC721-safeTransferFrom}.
	//  */
	// function safeTransferFrom(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId,
	// 	bytes memory _data
	// ) internal {
	// 	if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
	// 		revert NotApproved();
	// 	}

	// 	_safeTransfer(from, to, tokenId, _data);
	// }

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
	 *
	 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
	 * implement alternative mechanisms to perform token transfer, such as signature-based.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function safeTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		safeTransfer(from, to, tokenId, '');
	}

	function safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		transfer(from, to, tokenId);

		if (!_checkOnERC721Received(from, to, tokenId, _data)) {
			revert ERC721ReceiverNotImplemented();
		}
	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 * and stop existing when they are burned (`_burn`).
	 */
	function _exists(uint256 tokenId) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.mintedTokens[tokenId];
	}

	/**
	 * @dev Returns whether `spender` is allowed to manage `tokenId`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		if (!_exists(tokenId)) {
			revert TokenNotFound(tokenId);
		}
		address _owner = ownerOf(tokenId);
		return (spender == _owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(_owner, spender));
	}

	/**
	 * @dev Safely mints `tokenId` and transfers it to `to`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeMint(address to, uint256 tokenId) internal {
		_safeMint(to, tokenId, '');
	}

	/**
	 * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
	 * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
	 */
	function _safeMint(
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		_mint(to, tokenId);

		if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
			revert ERC721ReceiverNotImplemented();
		}
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - `to` cannot be the zero address.
	 *
	 * Emits a {Transfer} event.
	 */
	function _mint(address to, uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (to == address(0)) {
			revert ToAddressInvalid(to);
		}

		if (_exists(tokenId)) {
			revert TokenAlreadyExists(tokenId);
		}

		s.allTokens.push(tokenId);
		s.allTokensIndex[tokenId] = s.allTokens.length;
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length - 1;
		s.mintedTokens[tokenId] = true;

		emit Transfer(address(0), to, tokenId);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		bool canFacilitateClaim = _canFacilitateClaim(_msgSender(), tokenId);

		// Meems can be transferred if:
		// 1. They are wrapped and the sender can facilitate claim
		// 2. They are owned by this contract and the sender can facilitate claim
		// 3. They are the owner
		if (
			s.meems[tokenId].meemType == MeemType.Wrapped && !canFacilitateClaim
		) {
			revert NotTokenAdmin(tokenId);
		} else if (
			s.meems[tokenId].owner == address(this) && !canFacilitateClaim
		) {
			revert NotTokenAdmin(tokenId);
		} else if (ownerOf(tokenId) != from) {
			revert NotTokenOwner(tokenId);
		}

		if (to == address(0)) {
			revert ToAddressInvalid(address(0));
		}

		if (s.meems[tokenId].verifiedBy == address(0)) {
			revert MeemNotVerified();
		}

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		uint256 index = s.ownerTokenIdIndexes[from][tokenId];
		LibArray.removeAt(s.ownerTokenIds[from], index);
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length - 1;
		s.meems[tokenId].owner = to;

		emit Transfer(from, to, tokenId);
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
	}

	/**
	 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
	 * The call is not executed if the target address is not a contract.
	 *
	 * @param from address representing the previous owner of the given token ID
	 * @param to target address that will receive the tokens
	 * @param tokenId uint256 ID of the token to be transferred
	 * @param _data bytes optional data to send along with the call
	 * @return bool whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal returns (bool) {
		if (isContract(to)) {
			try
				IERC721TokenReceiver(to).onERC721Received(
					_msgSender(),
					from,
					tokenId,
					_data
				)
			returns (bytes4 retval) {
				return retval == IERC721TokenReceiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert ERC721ReceiverNotImplemented();
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	function _checkOnERC721Received(
		address _operator,
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal {
		uint256 size;
		assembly {
			size := extcodesize(_to)
		}
		if (size > 0) {
			require(
				ERC721_RECEIVED ==
					IERC721TokenReceiver(_to).onERC721Received(
						_operator,
						_from,
						_tokenId,
						_data
					),
				'LibERC721: Transfer rejected/failed by _to'
			);
		}
	}

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function _canFacilitateClaim(address user, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		Meem memory meem = LibMeem.getMeem(tokenId);
		bool isAdmin = LibAccessControl.hasRole(s.ADMIN_ROLE, user);
		if (
			!isAdmin ||
			(meem.parent == address(0) && meem.owner != address(this)) ||
			(meem.parent == address(this) && meem.owner != address(this))
		) {
			// Meem is an original or a child of another meem and can only be transferred by the owner
			return false;
		}

		return true;
	}
}
