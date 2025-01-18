// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@author Scenerio: Imagine a smart contract that distributes rewards to users. If the contract transfers Ether to all recipients in a loop, one malicious user can block the entire process by making their transaction fail.
contract VulnerableDosCallContract {
    address[] public recipients;
    mapping(address => uint256) public balances;

    function deposit() external payable {
        if (balances[msg.sender] == 0) {
            recipients.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
    }

    function distributeFunds() external {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = balances[recipient];

            if (amount > 0) {
                payable(recipient).transfer(amount);
                balances[recipient] = 0;
            }
        }
    }
}
