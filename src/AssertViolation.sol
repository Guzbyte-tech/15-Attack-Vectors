// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AssertViolation {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    // Deposit Ether
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    // Withdraw Ether
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;

        // Assert to ensure total supply is non-negative
        assert(totalSupply >= 0); // Potential issue if totalSupply becomes negative
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
