// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibReaction} from '../libraries/LibReaction.sol';
import {IReactionStandard, Reaction} from '../interfaces/MeemStandard.sol';

contract ReactionFacet is IReactionStandard {
	function addReaction(uint256 tokenId, string memory reaction)
		external
		override
	{
		LibReaction.addReaction(tokenId, reaction);
	}

	function removeReaction(uint256 tokenId, string memory reaction)
		external
		override
	{
		LibReaction.removeReaction(tokenId, reaction);
	}

	function getReactedAt(
		uint256 tokenId,
		address addy,
		string memory reaction
	) external view override returns (uint256) {
		return LibReaction.getReactedAt(tokenId, addy, reaction);
	}

	function setReactionTypes(uint256 tokenId, string[] memory reactionTypes)
		external
		override
	{
		LibReaction.setReactionTypes(tokenId, reactionTypes);
	}

	function getReactions(uint256 tokenId)
		external
		view
		override
		returns (Reaction[] memory)
	{
		return LibReaction.getReactions(tokenId);
	}
}
