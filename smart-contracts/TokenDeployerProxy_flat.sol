// SPDX-License-Identifier: MIT


// Sources flattened with hardhat v2.28.2 https://hardhat.org


// File @openzeppelin/contracts/utils/Context.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interfaces/IAggregatorV3.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chainlink Price Feed Interface
 * @dev Shared interface for Chainlink AggregatorV3 price feeds
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}


// File contracts/ChainlinkFeeManager.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;


/**
 * @title ChainlinkFeeManager
 * @dev Base contract for USD-denominated fee charging using Chainlink price feeds
 * @notice Inherit this contract to charge fees in native currency based on USD prices
 * 
 * Created by TokenKickstarter — https://tokenkickstarter.com
 */
abstract contract ChainlinkFeeManager is Ownable {
    // ============================================
    // STATE
    // ============================================
    AggregatorV3Interface public nativePriceFeed;   // Native/USD feed (BNB/USD, ETH/USD, MATIC/USD)
    address public feeRecipient;                     // Address receiving all fees
    uint256 public maxStaleness = 3600;              // Max price age in seconds (1 hour default)
    uint256 public fallbackNativePrice;              // Fallback price if Chainlink is down (8 decimals)
    mapping(address => bool) public isAuthorizedRelayer; // Relayers bypass fees

    // ============================================
    // EVENTS
    // ============================================
    event PriceFeedUpdated(address indexed newFeed);
    event FeeRecipientUpdated(address indexed newRecipient);
    event FallbackPriceUpdated(uint256 newPrice);
    event MaxStalenessUpdated(uint256 newStaleness);
    event RelayerStatusUpdated(address indexed relayer, bool status);

    // ============================================
    // ERRORS
    // ============================================
    error InsufficientFee(uint256 required, uint256 sent);
    error InvalidPriceFeed();
    error PriceFeedStale();
    error InvalidPrice();
    error ZeroAddress();

    // ============================================
    // PRICE FUNCTIONS
    // ============================================

    /**
     * @dev Get the current native token price in USD (8 decimals)
     * @return price USD price with 8 decimals, or fallback price if feed is unavailable
     */
    function getNativePrice() public view returns (uint256 price) {
        if (address(nativePriceFeed) == address(0)) {
            require(fallbackNativePrice > 0, "No price feed or fallback");
            return fallbackNativePrice;
        }
        
        try nativePriceFeed.latestRoundData() returns (
            uint80, int256 answer, uint256, uint256 updatedAt, uint80
        ) {
            if (answer <= 0) {
                // Price invalid — use fallback
                if (fallbackNativePrice > 0) return fallbackNativePrice;
                revert InvalidPrice();
            }
            
            if (maxStaleness > 0 && block.timestamp - updatedAt > maxStaleness) {
                // Price stale — use fallback
                if (fallbackNativePrice > 0) return fallbackNativePrice;
                revert PriceFeedStale();
            }
            
            return uint256(answer);
        } catch {
            // Chainlink call failed — use fallback
            if (fallbackNativePrice > 0) return fallbackNativePrice;
            revert InvalidPriceFeed();
        }
    }

    /**
     * @dev Calculate how much native currency is needed for a given USD amount
     * @param usdAmount Fee in USD with 8 decimals (e.g., 50e8 = $50)
     * @return nativeAmount Required native tokens in wei (18 decimals)
     */
    function getRequiredNative(uint256 usdAmount) public view returns (uint256 nativeAmount) {
        if (usdAmount == 0) return 0;
        
        uint256 nativePrice = getNativePrice(); // 8 decimals
        // nativeAmount = (usdAmount * 1e18) / nativePrice
        // Example: $50 when BNB=$600 → (50e8 * 1e18) / 600e8 = 0.0833e18 = 0.0833 BNB
        return (usdAmount * 1e18) / nativePrice;
    }

    /**
     * @dev Internal: charge a USD-denominated fee in native currency
     * @param usdAmount Fee in USD with 8 decimals
     * @return feeCharged The actual native amount charged
     */
    function _chargeUsdFee(uint256 usdAmount) internal returns (uint256 feeCharged) {
        if (usdAmount == 0) return 0;
        if (isAuthorizedRelayer[msg.sender]) return 0; // Relayers bypass fees

        uint256 required = getRequiredNative(usdAmount);
        if (msg.value < required) {
            revert InsufficientFee(required, msg.value);
        }

        // Transfer fee to recipient
        if (required > 0 && feeRecipient != address(0)) {
            (bool success, ) = payable(feeRecipient).call{value: required}("");
            require(success, "Fee transfer failed");
        }

        // Refund excess
        uint256 excess = msg.value - required;
        if (excess > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: excess}("");
            require(refunded, "Refund failed");
        }

        return required;
    }

    // ============================================
    // ADMIN FUNCTIONS
    // ============================================

    /**
     * @dev Update Chainlink price feed address
     */
    function setPriceFeed(address newFeed) external onlyOwner {
        if (newFeed == address(0)) revert ZeroAddress();
        nativePriceFeed = AggregatorV3Interface(newFeed);
        emit PriceFeedUpdated(newFeed);
    }

    /**
     * @dev Update fee recipient
     */
    function setFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert ZeroAddress();
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /**
     * @dev Update fallback native price (8 decimals)
     * @notice Set to 0 to disable fallback (strict Chainlink-only mode)
     */
    function setFallbackPrice(uint256 newPrice) external onlyOwner {
        fallbackNativePrice = newPrice;
        emit FallbackPriceUpdated(newPrice);
    }

    /**
     * @dev Update max staleness for price feed
     * @param newStaleness Max age in seconds (0 = no staleness check)
     */
    function setMaxStaleness(uint256 newStaleness) external onlyOwner {
        maxStaleness = newStaleness;
        emit MaxStalenessUpdated(newStaleness);
    }

    /**
     * @dev Set authorized relayer status
     */
    function setRelayerStatus(address relayer, bool status) external onlyOwner {
        isAuthorizedRelayer[relayer] = status;
        emit RelayerStatusUpdated(relayer, status);
    }
}


// File contracts/TokenDeployerProxy.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

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
