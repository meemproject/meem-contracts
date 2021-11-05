// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibArray {
	function removeAt(uint256[] storage array, uint256 index)
		internal
		returns (uint256[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}
}
