// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableReplay {
    mapping(address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 1000 ether; // Initial balance for demonstration
    }

    function deposit() external payable {
        require(msg.value > 0, "Amount should be greater than zero");
        balances[msg.sender] = msg.value;
    }

    function transfer(
        address from,
        address to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Create the message hash
        bytes32 message = keccak256(abi.encodePacked(from, to, amount));
        bytes32 ethSignedMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );

        // Recover the signer
        address signer = ecrecover(ethSignedMessage, v, r, s);
        require(signer == from, "Invalid signature");

        // Transfer tokens
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
    }

    function getbalance(address _addr) external view returns (uint256) {
        return balances[_addr];
    }
}
