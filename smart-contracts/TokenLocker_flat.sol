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


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/interfaces/IERC165.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

pragma solidity >=0.4.16;


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/interfaces/IERC20.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

pragma solidity >=0.4.16;


// File @openzeppelin/contracts/interfaces/IERC1363.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

pragma solidity >=0.6.2;


/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
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


// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


// File contracts/TokenLocker.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;




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
