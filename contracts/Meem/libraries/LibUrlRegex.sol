// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library URLRegex {
	struct State {
		bool accepts;
		function(bytes1) internal pure returns (State memory) func;
	}

	string public constant regex =
		"https?:\\//[A-Za-z0-9-._~:/[]@%]+'&'()*+,;%]+";

	function s0(bytes1 c) internal pure returns (State memory) {
		c = c;
		return State(false, s0);
	}

	function s1(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 104) {
			return State(false, s2);
		}

		return State(false, s0);
	}

	function s2(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 116) {
			return State(false, s3);
		}

		return State(false, s0);
	}

	function s3(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 116) {
			return State(false, s4);
		}

		return State(false, s0);
	}

	function s4(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 112) {
			return State(false, s5);
		}

		return State(false, s0);
	}

	function s5(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 115) {
			return State(false, s6);
		}

		return State(false, s0);
	}

	function s6(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 58) {
			return State(false, s7);
		}

		return State(false, s0);
	}

	function s7(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 47) {
			return State(false, s8);
		}

		return State(false, s0);
	}

	function s8(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 47) {
			return State(false, s9);
		}

		return State(false, s0);
	}

	function s9(bytes1 c) internal pure returns (State memory) {
		if (
			uint8(c) == 45 ||
			uint8(c) == 46 ||
			uint8(c) == 47 ||
			(uint8(c) >= 48 && uint8(c) <= 57) ||
			uint8(c) == 58 ||
			(uint8(c) >= 65 && uint8(c) <= 90) ||
			uint8(c) == 91 ||
			uint8(c) == 95 ||
			(uint8(c) >= 97 && uint8(c) <= 122) ||
			uint8(c) == 126
		) {
			return State(false, s10);
		}

		return State(false, s0);
	}

	function s10(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 64) {
			return State(false, s11);
		}

		return State(false, s0);
	}

	function s11(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 37) {
			return State(false, s12);
		}

		return State(false, s0);
	}

	function s12(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 93) {
			return State(false, s13);
		}

		return State(false, s0);
	}

	function s13(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 43) {
			return State(false, s14);
		}

		return State(false, s0);
	}

	function s14(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 39) {
			return State(false, s15);
		}

		return State(false, s0);
	}

	function s15(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 38) {
			return State(false, s16);
		}

		return State(false, s0);
	}

	function s16(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 39) {
			return State(false, s17);
		}

		return State(false, s0);
	}

	function s17(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 40) {
			return State(false, s18);
		}

		return State(false, s0);
	}

	function s18(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 41) {
			return State(false, s19);
		}

		return State(false, s0);
	}

	function s19(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 42) {
			return State(false, s20);
		}

		return State(false, s0);
	}

	function s20(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 43) {
			return State(false, s21);
		}

		return State(false, s0);
	}

	function s21(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 44) {
			return State(false, s22);
		}

		return State(false, s0);
	}

	function s22(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 59) {
			return State(false, s23);
		}

		return State(false, s0);
	}

	function s23(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 37) {
			return State(false, s24);
		}

		return State(false, s0);
	}

	function s24(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 93) {
			return State(true, s25);
		}

		return State(false, s0);
	}

	function s25(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 93) {
			return State(true, s26);
		}

		return State(false, s0);
	}

	function s26(bytes1 c) internal pure returns (State memory) {
		if (uint8(c) == 93) {
			return State(true, s26);
		}

		return State(false, s0);
	}

	function matches(string memory input) public pure returns (bool) {
		State memory cur = State(false, s1);

		for (uint256 i = 0; i < bytes(input).length; i++) {
			bytes1 c = bytes(input)[i];

			cur = cur.func(c);
		}

		return cur.accepts;
	}
}
