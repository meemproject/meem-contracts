// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface MeemStandard {
	enum Chain {
		Ethereum,
		Polygon,
		Cardano
	}

	enum Permission {
		Owner,
		Anyone,
		Addresses,
		Holders
	}

	struct Split {
		address toAddress;
		uint256 amount;
	}
	struct MeemPermission {
		Permission permission;
		address[] addresses;
		uint256 numTokens;
		address lockedBy;
	}

	struct MeemProperties {
		MeemPermission[] copyPermissions;
		MeemPermission[] remixPermissions;
		MeemPermission[] readPermissions;
		Chain chain;
		address parent;
		uint256 parentTokenId;
		Split[] splits;
		uint256 totalCopies;
	}

	function mint(
		address to,
		string memory mTokenURI,
		MeemProperties memory properties
	) external;
}
