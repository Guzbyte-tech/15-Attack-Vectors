// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@dev This contract allows users to claim a reward if they solve a puzzle. However, it is vulnerable because it does not verify who actually solved the puzzle—it just rewards the first caller.
contract VulnerableFrontRunning {
    address public owner;
    uint256 public rewardAmount = 5 ether;
    bytes32 public solutionHash;

    constructor(bytes32 _solutionHash) payable {
        owner = msg.sender;
        solutionHash = _solutionHash;
    }

    function claimReward(string memory solution) external {
        require(address(this).balance >= rewardAmount, "Not enough funds");
        require(
            keccak256(abi.encodePacked(solution)) == solutionHash,
            "Incorrect solution"
        );

        // ❌ Front-running vulnerability: first valid claim gets the reward
        payable(msg.sender).transfer(rewardAmount);
    }

    function depositFunds() external payable {}

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
