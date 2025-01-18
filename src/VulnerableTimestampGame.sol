// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@dev A gambling game where users bet on the outcome of a number derived from block.timestamp. 
///@dev This is a vulnerable contract allows users to bet on a random number generated using block.timestamp

contract VulnerableTimestampGame {
    address public owner;
    uint256 public lastWinTime;

    constructor() {
        owner = msg.sender;
    }

    function play(uint256 guessedNumber) external payable {
        require(msg.value == 1 ether, "Must send 1 ether to play");

        // ❌ EXPLOIT: Uses block.timestamp, which miners can manipulate
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;

        if (random == guessedNumber) {
            payable(msg.sender).transfer(2 ether);
            lastWinTime = block.timestamp;
        }
    }

    function depositFunds() external payable {}

    function getLastWinTime() external view returns (uint256) {
        return lastWinTime;
    }
}
