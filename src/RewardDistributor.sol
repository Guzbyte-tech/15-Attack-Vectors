// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableRewardDistributor {
    uint256 public totalContributions;
    uint256 public rewardPool;
    mapping(address => uint256) public contributions;

    constructor() {
        rewardPool = 10 ether; // Initial reward pool
    }

    // Contribute to the reward pool
    function contribute() external payable {
        require(msg.value > 0, "Must contribute some ETH");
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
    }

    // Claim rewards proportional to contributions
    function claimReward() external {
        require(contributions[msg.sender] > 0, "No contributions to claim reward");

        // Vulnerable reward calculation
        uint256 reward = (contributions[msg.sender] * rewardPool) / totalContributions;

        // Reset user's contribution
        contributions[msg.sender] = 0;

        // Send reward to user
        payable(msg.sender).transfer(reward);
    }

    // Fallback to accept ETH
    receive() external payable {}
}
