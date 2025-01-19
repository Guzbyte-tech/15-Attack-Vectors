// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AssertViolation.sol";

contract ExploitAssertViolation {
    AssertViolation public target;

    constructor(address _target) {
        target = AssertViolation(_target);
    }

    // Exploit: Manipulate balances and trigger assert failure
    function exploit() external payable {
        // Deposit funds into the contract
        target.deposit{value: msg.value}();

        // Attempt to withdraw more than available to cause an underflow
        uint256 withdrawAmount = msg.value + 1 ether;
        target.withdraw(withdrawAmount);
    }

    // Fallback to handle incoming Ether
    receive() external payable {}
}

contract AssertViolationTest is Test {
    AssertViolation public target;
    ExploitAssertViolation public attacker;

    function setUp() public {
        // Deploy the vulnerable contract
        target = new AssertViolation();

        // Deploy the attacker contract
        attacker = new ExploitAssertViolation(address(target));
    }

    function testAssertViolationExploit() public {
        // Fund the attacker contract with 1 Ether
        vm.deal(address(attacker), 1 ether);

        // Execute the exploit
        vm.expectRevert(); // Expect an assert failure
        attacker.exploit{value: 1 ether}();
    }
}
