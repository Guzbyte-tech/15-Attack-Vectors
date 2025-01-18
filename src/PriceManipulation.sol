// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract VulnerablePriceFeed {
    address public uniswapPair;
    address public tokenA;
    address public tokenB;

    constructor(address _uniswapPair, address _tokenA, address _tokenB) {
        uniswapPair = _uniswapPair;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function getPrice() public view returns (uint256 price) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapPair)
            .getReserves();

        if (IUniswapV2Pair(uniswapPair).token0() == tokenA) {
            price = (uint256(reserve1) * 1e18) / reserve0; // tokenB/tokenA price
        } else {
            price = (uint256(reserve0) * 1e18) / reserve1; // tokenA/tokenB price
        }
    }
}
