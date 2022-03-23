// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibERC721} from './LibERC721.sol';
import {LibArray} from './LibArray.sol';
import {Reaction} from '../interfaces/MeemStandard.sol';
import {AlreadyReacted, ReactionNotFound} from './Errors.sol';

library LibReaction {
	event TokenReactionAdded(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event TokenReactionRemoved(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event TokenReactionTypesSet(uint256 tokenId, string[] reactionTypes);

	function addReaction(uint256 tokenId, string memory reaction) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.addressReactionsAt[tokenId][reaction][msg.sender] != 0) {
			revert AlreadyReacted();
		}

		s.addressReactions[msg.sender][tokenId].push(reaction);
		s.addressReactionsIndex[msg.sender][tokenId][reaction] =
			s.addressReactions[msg.sender][tokenId].length -
			1;
		s.addressReactionsAt[tokenId][reaction][msg.sender] = block.timestamp;

		s.tokenReactions[tokenId][reaction]++;

		emit TokenReactionAdded(
			tokenId,
			msg.sender,
			reaction,
			s.tokenReactions[tokenId][reaction]
		);
	}

	function removeReaction(uint256 tokenId, string memory reaction) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.addressReactionsAt[tokenId][reaction][msg.sender] == 0) {
			revert ReactionNotFound();
		}

		LibArray.removeAt(
			s.addressReactions[msg.sender][tokenId],
			s.addressReactionsIndex[msg.sender][tokenId][reaction]
		);

		s.addressReactionsAt[tokenId][reaction][msg.sender] = 0;

		s.tokenReactions[tokenId][reaction]--;

		emit TokenReactionRemoved(
			tokenId,
			msg.sender,
			reaction,
			s.tokenReactions[tokenId][reaction]
		);
	}

	function getReactedAt(
		uint256 tokenId,
		address addy,
		string memory reaction
	) internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.addressReactionsAt[tokenId][reaction][addy] == 0) {
			revert ReactionNotFound();
		}

		return s.addressReactionsAt[tokenId][reaction][addy];
	}

	function setReactionTypes(uint256 tokenId, string[] memory reactionTypes)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.meems[tokenId].reactionTypes = reactionTypes;

		emit TokenReactionTypesSet(tokenId, reactionTypes);
	}

	function getReactions(uint256 tokenId)
		internal
		view
		returns (Reaction[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		Reaction[] memory reactions = new Reaction[](
			s.meems[tokenId].reactionTypes.length
		);

		for (uint256 i = 0; i < s.meems[tokenId].reactionTypes.length; i++) {
			reactions[i].reaction = s.meems[tokenId].reactionTypes[i];
			reactions[i].count = s.tokenReactions[tokenId][
				s.meems[tokenId].reactionTypes[i]
			];
		}

		return reactions;
	}
}
