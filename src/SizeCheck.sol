// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SizeCheck {
    event Success(address sender);

    function onlyEOA() external {
        // Check if the caller is a contract
        // require(tx.origin == msg.sender, "Only EOA allowed"); // Prevent proxy calls
        require(msg.sender.code.length == 0, "Contracts not allowed");

        emit Success(msg.sender);
    }
}
