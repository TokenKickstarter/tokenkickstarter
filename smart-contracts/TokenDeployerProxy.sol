// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ChainlinkFeeManager.sol";

/**
 * @title TokenDeployerProxy
 * @notice Deploys token contracts on behalf of users while collecting platform fees
 * @dev This contract receives bytecode and deploys it using CREATE opcode
 *      The fee is collected via Chainlink USD pricing and the deployed
 *      contract's ownership is transferred to the user
 * 
 * Fee Structure:
 *   - Basic token creation: $5 USD (configurable by owner)
 * 
 * Created by TokenKickstarter — https://tokenkickstarter.com
 */
contract TokenDeployerProxy is ChainlinkFeeManager {
    // Fee stored in USD with 8 decimals (matching Chainlink precision)
    uint256 public creationFeeUsd;
    
    // Events
    event TokenDeployed(address indexed deployer, address indexed tokenAddress, uint256 fee);
    event CreationFeeUpdated(uint256 oldFeeUsd, uint256 newFeeUsd);
    
    /**
     * @param priceFeed_ Chainlink native/USD price feed (BNB/USD, ETH/USD, etc.)
     * @param feeRecipient_ Address receiving all fees
     * @param creationFeeUsd_ Initial creation fee in USD (8 decimals, e.g. 5e8 = $5)
     */
    constructor(
        address priceFeed_,
        address feeRecipient_,
        uint256 creationFeeUsd_
    ) Ownable(msg.sender) {
        require(priceFeed_ != address(0), "Invalid price feed");
        require(feeRecipient_ != address(0), "Invalid recipient");
        nativePriceFeed = AggregatorV3Interface(priceFeed_);
        feeRecipient = feeRecipient_;
        creationFeeUsd = creationFeeUsd_;
    }
    
    /**
     * @notice Deploy a token contract from bytecode
     * @param bytecode The compiled bytecode of the token contract
     * @return tokenAddress The address of the deployed token contract
     */
    function deployToken(bytes calldata bytecode) external payable returns (address tokenAddress) {
        require(bytecode.length > 0, "Empty bytecode");
        
        // Charge fee in native currency using Chainlink USD conversion
        uint256 feeCharged = _chargeUsdFee(creationFeeUsd);
        
        // Deploy the contract using CREATE opcode
        assembly {
            // Get free memory pointer
            let ptr := mload(0x40)
            
            // Copy bytecode to memory
            calldatacopy(ptr, bytecode.offset, bytecode.length)
            
            // Deploy using CREATE
            tokenAddress := create(0, ptr, bytecode.length)
        }
        
        require(tokenAddress != address(0), "Deployment failed");
        
        emit TokenDeployed(msg.sender, tokenAddress, feeCharged);
        
        return tokenAddress;
    }
    
    /**
     * @notice Update the creation fee in USD
     * @param newFeeUsd The new fee in USD with 8 decimals (e.g. 5e8 = $5)
     */
    function setCreationFeeUsd(uint256 newFeeUsd) external onlyOwner {
        emit CreationFeeUpdated(creationFeeUsd, newFeeUsd);
        creationFeeUsd = newFeeUsd;
    }
    
    /**
     * @notice Get the creation fee in native currency for the frontend
     * @return fee Native currency amount in wei
     * @return feeUsd USD amount with 8 decimals
     */
    function getCreationFeeInNative() external view returns (uint256 fee, uint256 feeUsd) {
        feeUsd = creationFeeUsd;
        fee = getRequiredNative(feeUsd);
    }
    
    /**
     * @notice Legacy compatibility — returns fee in native for existing UI
     */
    function getCreationFee() external view returns (uint256) {
        return getRequiredNative(creationFeeUsd);
    }
    
    /**
     * @notice Withdraw any stuck ETH/BNB (emergency function)
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
    
    // Accept ETH/BNB
    receive() external payable {}
}
