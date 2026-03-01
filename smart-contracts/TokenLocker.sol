// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ChainlinkFeeManager.sol";

/**
 * @title TokenLocker
 * @dev Lock tokens or LP tokens for a specified period
 * @notice Fees are denominated in USD and converted to native currency via Chainlink
 * 
 * Fee Structure:
 *   - Lock fee: $0 (free, configurable by owner)
 * 
 * Created by TokenKickstarter — https://tokenkickstarter.com
 */
contract TokenLocker is ReentrancyGuard, ChainlinkFeeManager {
    using SafeERC20 for IERC20;
    
    struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 unlockTime;
        bool isLP;
        bool unlocked;
    }
    
    // State
    uint256 public nextLockId;
    uint256 public lockFeeUsd;  // USD fee with 8 decimals (0 = free)
    
    // Mappings
    mapping(uint256 => Lock) public locks;
    mapping(address => uint256[]) public userLocks;
    mapping(address => uint256[]) public tokenLocks;
    
    // Events
    event TokensLocked(
        uint256 indexed lockId,
        address indexed token,
        address indexed owner,
        uint256 amount,
        uint256 unlockTime,
        bool isLP
    );
    event TokensUnlocked(uint256 indexed lockId, address indexed owner, uint256 amount);
    event LockExtended(uint256 indexed lockId, uint256 newUnlockTime);
    event LockFeeUpdated(uint256 newFeeUsd);
    
    /**
     * @param priceFeed_ Chainlink native/USD price feed (BNB/USD, ETH/USD, etc.)
     */
    constructor(address priceFeed_) Ownable(msg.sender) {
        require(priceFeed_ != address(0), "Invalid price feed");
        nativePriceFeed = AggregatorV3Interface(priceFeed_);
        feeRecipient = msg.sender;
        lockFeeUsd = 0; // Free by default
    }
    
    /**
     * @dev Lock tokens
     */
    function lockTokens(
        address token_,
        uint256 amount_,
        uint256 unlockTime_,
        bool isLP_
    ) external payable nonReentrant returns (uint256) {
        require(token_ != address(0), "Invalid token");
        require(amount_ > 0, "Amount must be > 0");
        require(unlockTime_ > block.timestamp, "Unlock time must be future");
        
        // Charge fee in native currency (Chainlink conversion) — currently free
        _chargeUsdFee(lockFeeUsd);
        
        // Transfer tokens to this contract
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        
        // Create lock
        uint256 lockId = nextLockId++;
        locks[lockId] = Lock({
            id: lockId,
            token: token_,
            owner: msg.sender,
            amount: amount_,
            unlockTime: unlockTime_,
            isLP: isLP_,
            unlocked: false
        });
        
        userLocks[msg.sender].push(lockId);
        tokenLocks[token_].push(lockId);
        
        emit TokensLocked(lockId, token_, msg.sender, amount_, unlockTime_, isLP_);
        
        return lockId;
    }
    
    /**
     * @dev Unlock tokens after unlock time
     */
    function unlock(uint256 lockId) external nonReentrant {
        Lock storage lock = locks[lockId];
        require(lock.owner == msg.sender, "Not owner");
        require(!lock.unlocked, "Already unlocked");
        require(block.timestamp >= lock.unlockTime, "Still locked");
        
        lock.unlocked = true;
        
        IERC20(lock.token).safeTransfer(msg.sender, lock.amount);
        
        emit TokensUnlocked(lockId, msg.sender, lock.amount);
    }
    
    /**
     * @dev Extend lock time
     */
    function extendLock(uint256 lockId, uint256 newUnlockTime) external {
        Lock storage lock = locks[lockId];
        require(lock.owner == msg.sender, "Not owner");
        require(!lock.unlocked, "Already unlocked");
        require(newUnlockTime > lock.unlockTime, "Must extend");
        
        lock.unlockTime = newUnlockTime;
        
        emit LockExtended(lockId, newUnlockTime);
    }
    
    // ============================================
    // Admin functions
    // ============================================
    
    function setLockFeeUsd(uint256 newFeeUsd) external onlyOwner {
        lockFeeUsd = newFeeUsd;
        emit LockFeeUpdated(newFeeUsd);
    }
    
    // ============================================
    // View functions (for frontend)
    // ============================================
    
    /**
     * @dev Get lock fee in native currency for the frontend
     * @return fee Native currency amount in wei
     * @return feeUsd USD amount with 8 decimals
     */
    function getLockFeeInNative() external view returns (uint256 fee, uint256 feeUsd) {
        feeUsd = lockFeeUsd;
        fee = getRequiredNative(feeUsd);
    }
    
    /**
     * @dev Legacy compatibility — returns fee in native for internal presale calls
     */
    function lockFee() external view returns (uint256) {
        return getRequiredNative(lockFeeUsd);
    }
    
    function getLock(uint256 lockId) external view returns (Lock memory) {
        return locks[lockId];
    }
    
    function getUserLocks(address user) external view returns (uint256[] memory) {
        return userLocks[user];
    }
    
    function getTokenLocks(address token) external view returns (uint256[] memory) {
        return tokenLocks[token];
    }
    
    function getActiveLocks(address user) external view returns (Lock[] memory) {
        uint256[] memory lockIds = userLocks[user];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < lockIds.length; i++) {
            if (!locks[lockIds[i]].unlocked) {
                activeCount++;
            }
        }
        
        Lock[] memory activeLocks = new Lock[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < lockIds.length; i++) {
            if (!locks[lockIds[i]].unlocked) {
                activeLocks[index++] = locks[lockIds[i]];
            }
        }
        
        return activeLocks;
    }
}

