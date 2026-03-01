// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ContributionCollector.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ChainlinkFeeManagerUpgradeable.sol";

/**
 * @title ContributionCollectorFactory
 * @dev Factory to deploy ContributionCollector contracts on secondary chains
 * @notice Deploy this on ETH, Polygon, Base - NOT on primary chain (BSC)
 * @notice Fees are denominated in USD and converted to native currency via Chainlink
 * 
 * Fee Structure:
 *   - Collector creation fee: $5 USD (configurable by owner)
 *   - Authorized relayers bypass all fees
 * 
 * Created by TokenKickstarter — https://tokenkickstarter.com
 */
contract ContributionCollectorFactory is Initializable, ChainlinkFeeManagerUpgradeable, UUPSUpgradeable {
    // ============================================
    // EVENTS
    // ============================================
    event CollectorCreated(
        address indexed collector,
        bytes32 indexed presaleId,
        uint256 primaryChainId,
        address primaryPresale,
        address indexed owner
    );
    event CreationFeeUpdated(uint256 newFeeUsd);
    
    // ============================================
    // STATE
    // ============================================
    address[] public allCollectors;
    mapping(bytes32 => address) public collectorByPresaleId;
    
    // USD Fee (8 decimals, matching Chainlink precision)
    uint256 public creationFeeUsd;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @param priceFeed_ Chainlink native/USD price feed (BNB/USD, ETH/USD, etc.)
     */
    function initialize(address priceFeed_) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ChainlinkFeeManager_init(priceFeed_, msg.sender);
        
        creationFeeUsd = 5e8;  // $5 USD
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // ============================================
    // CREATE COLLECTOR
    // ============================================
    
    /**
     * @dev Create a new ContributionCollector
     * @param presaleId_ Unique identifier linking to primary chain presale
     * @param primaryChainId_ Chain ID where tokens exist (e.g., BSC = 56)
     * @param primaryPresale_ Address of MultiCurrencyPresale on primary chain
     * @param softCap_ Soft cap in native currency (18 decimals)
     * @param hardCap_ Hard cap in native currency (18 decimals)
     * @param minContribution_ Minimum contribution
     * @param maxContribution_ Maximum contribution
     * @param startTime_ Presale start time
     * @param endTime_ Presale end time
     * @param tokenName_ Name of token being sold
     * @param tokenSymbol_ Symbol of token being sold
     * @param paymentTokens_ Array of accepted payment tokens
     * @param rates_ Array of rates for each payment token
     * @param referralPercent_ Referral bonus percentage
     */
    function createCollector(
        bytes32 presaleId_,
        uint256 primaryChainId_,
        address primaryPresale_,
        uint256 softCap_,
        uint256 hardCap_,
        uint256 minContribution_,
        uint256 maxContribution_,
        uint256 startTime_,
        uint256 endTime_,
        string memory tokenName_,
        string memory tokenSymbol_,
        address[] memory paymentTokens_,
        uint256[] memory rates_,
        uint256 referralPercent_
    ) external payable returns (address) {
        require(collectorByPresaleId[presaleId_] == address(0), "Presale already exists");
        
        // Charge fee in native currency (Chainlink USD conversion)
        // Authorized relayers bypass fees automatically via _chargeUsdFee
        _chargeUsdFee(creationFeeUsd);
        
        // Create collector
        ContributionCollector collector = new ContributionCollector(
            presaleId_,
            primaryChainId_,
            primaryPresale_,
            softCap_,
            hardCap_,
            minContribution_,
            maxContribution_,
            startTime_,
            endTime_,
            tokenName_,
            tokenSymbol_,
            msg.sender,
            paymentTokens_,
            rates_,
            referralPercent_
        );
        
        address collectorAddress = address(collector);
        allCollectors.push(collectorAddress);
        collectorByPresaleId[presaleId_] = collectorAddress;
        
        emit CollectorCreated(
            collectorAddress,
            presaleId_,
            primaryChainId_,
            primaryPresale_,
            msg.sender
        );
        
        return collectorAddress;
    }
    
    // ============================================
    // ADMIN FUNCTIONS
    // ============================================
    
    function setCreationFeeUsd(uint256 newFeeUsd) external onlyOwner {
        creationFeeUsd = newFeeUsd;
        emit CreationFeeUpdated(newFeeUsd);
    }
    
    // ============================================
    // VIEW FUNCTIONS
    // ============================================
    
    /**
     * @dev Get creation fee in native currency for the frontend
     * @return fee Native currency amount in wei
     * @return feeUsd USD amount with 8 decimals
     */
    function getCreationFeeInNative() external view returns (uint256 fee, uint256 feeUsd) {
        feeUsd = creationFeeUsd;
        fee = getRequiredNative(feeUsd);
    }
    
    function getAllCollectors() external view returns (address[] memory) {
        return allCollectors;
    }
    
    function getCollectorCount() external view returns (uint256) {
        return allCollectors.length;
    }
    
    /**
     * @dev Get collector address by presale ID
     */
    function getCollector(bytes32 presaleId_) external view returns (address) {
        return collectorByPresaleId[presaleId_];
    }
}
