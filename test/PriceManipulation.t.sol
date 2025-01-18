// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VulnerableLending.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PriceManipulationTest is Test {
    VulnerableLending public lending;
    PriceManipulationAttack public attacker;
    IUniswapV2Pair public pair;
    IERC20 public token;
    
    address public constant FLASH_LOAN_PROVIDER = address(0x1);
    address public constant ATTACKER = address(0x2);
    
    function setUp() public {
        // Deploy mock contracts and set up test environment
        // In real testing, you'd need to fork mainnet and use actual protocols
        
        // Deploy vulnerable lending protocol
        lending = new VulnerableLending(address(pair), address(token));
        
        // Deploy attacker contract
        attacker = new PriceManipulationAttack(
            address(pair),
            address(lending),
            address(token)
        );
        
        // Setup initial balances and approvals
        deal(address(token), ATTACKER, 100 ether);
        vm.prank(ATTACKER);
        token.approve(address(attacker), type(uint256).max);
    }
    
    function testPriceManipulation() public {
        // Record initial state
        uint256 initialPrice = lending.getPrice();
        uint256 initialAttackerBalance = token.balanceOf(ATTACKER);
        
        // Perform attack
        vm.prank(ATTACKER);
        attacker.attack(FLASH_LOAN_PROVIDER, 1000 ether);
        
        // Verify attack success
        uint256 finalPrice = lending.getPrice();
        uint256 finalAttackerBalance = token.balanceOf(ATTACKER);
        
        assertTrue(finalPrice > initialPrice * 2, "Price should be manipulated higher");
        assertTrue(
            finalAttackerBalance > initialAttackerBalance,
            "Attacker should profit"
        );
    }
}