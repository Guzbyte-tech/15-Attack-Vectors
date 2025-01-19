// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@dev This is a vulnerable contract that make a delegate call without checking if the target address to make delegate call to is the right address.
contract Vulnerable {
    address public owner;

    constructor() {
        owner = msg.sender; // Initial owner
    }

    function execute(address target, bytes calldata data) external {
        require(msg.sender == owner, "Not the owner"); // Only owner can execute
        (bool success, ) = target.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}
