/**
 * Token: TokenKickstarter
 * Symbol: TKS
 * Website: https://tokenkickstarter.com
 * Telegram: https://t.me/tokenkickstarter
 * X: https://x.com/TokenKickstart
 * TikTok: https://www.tiktok.com/@tokenkickstarter
 * GitHub: https://github.com/TokenKickstarter
 * Medium: https://medium.com/@TokenKickstarter
 * 
 * Created with Love — https://tokenkickstarter.com
 * 
 * @title TokenKickstarter
 * @dev Enhanced ERC20 token with security hardening and advanced features.
 * @notice This token includes reentrancy protection, two-step ownership, 
 *         optional blacklist, airdrop, trade cooldown, and anti-whale features.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============================================
// Interfaces
// ============================================

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// ============================================
// Custom Errors (Gas Optimization - Solidity 0.8.4+)
// ============================================

/// @dev Thrown when caller is not the owner
error NotOwner();
/// @dev Thrown when caller is not the pending owner
error NotPendingOwner();
/// @dev Thrown when address is zero
error ZeroAddress();
/// @dev Thrown when address is blacklisted
error Blacklisted();
/// @dev Thrown when token transfers are paused
error TransfersPaused();
/// @dev Thrown when trade cooldown is active
error CooldownActive();
/// @dev Thrown when max transaction exceeded
error MaxTransactionExceeded();
/// @dev Thrown when max wallet exceeded
error MaxWalletExceeded();
/// @dev Thrown when tax exceeds maximum
error TaxTooHigh();
/// @dev Thrown when feature is disabled
error FeatureDisabled();
/// @dev Thrown when insufficient balance
error InsufficientBalance();
/// @dev Thrown when arrays length mismatch
error ArrayLengthMismatch();
/// @dev Thrown when reentrancy detected
error ReentrantCall();


// ============================================
// Libraries
// ============================================

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Note: Solidity 0.8+ has built-in overflow checks, but SafeMath is kept for consistency.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}

/**
 * @dev Collection of functions related to the address type.
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value");
    }
}

// ============================================
// Abstract Contracts
// ============================================

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Reentrancy guard to prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Two-step ownership transfer for enhanced security.
 */
contract Ownable2Step is Context {
    address private _owner;
    address private _pendingOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }
    
    /**
     * @dev Starts the ownership transfer. New owner must call acceptOwnership().
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(_owner, newOwner);
    }
    
    /**
     * @dev New owner accepts ownership. Completes the two-step transfer.
     */
    function acceptOwnership() public virtual {
        require(_msgSender() == _pendingOwner, "Ownable: caller is not the pending owner");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _pendingOwner = address(0);
    }
    
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }
}

// ============================================
// Main Contract
// ============================================

contract TokenKickstarter is Context, IERC20, Ownable2Step, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    // ============================================
    // Token Configuration (Hardcoded)
    // ============================================
    string private _name = "TokenKickstarter";
    string private _symbol = "TKS";
    uint8 private _decimals = 18;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    // ============================================
    // Feature Flags
    // ============================================
    bool public reflectionEnabled = true;
    bool public autoLiquidityEnabled = false;
    bool public isMintable = true;
    bool public isPausable = true;
    bool public isPaused = false;
    bool public blacklistEnabled = true;
    bool public tradeCooldownEnabled = true;
    bool public earlySellPenaltyEnabled = true;
    
    // ============================================
    // Early Sell Penalty Configuration
    // ============================================
    uint256 public earlySellPenaltyDuration = 3600; // in seconds
    uint256 public earlySellPenaltyTax = 500; // additional tax in basis points
    mapping(address => uint256) private _tokenAcquisitionTime;
    
    // ============================================
    // Vesting/Lock Configuration
    // ============================================
    bool public vestingEnabled = false;
    uint256 public vestingAmount = 0 * 10**18;
    uint256 public vestingReleaseTime = 0; // Unix timestamp
    address public vestingBeneficiary = 0x655F76440B5Eb86b3bc40Fa710a84E17a27EF8a3;
    bool public vestingClaimed = false;
    
    // ============================================
    // EIP-2612 Permit Configuration
    // ============================================
    bool public permitEnabled = true;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping(address => uint256) public nonces;
    
    // ============================================
    // Staking Support Configuration
    // ============================================
    bool public stakingEnabled = true;
    mapping(address => bool) public authorizedStakingPools;
    
    // ============================================
    // Tax Configuration (in basis points, 100 = 1%)
    // ============================================
    uint256 public buyTax = 0;
    uint256 public sellTax = 0;
    uint256 public transferTax = 0;
    uint256 public reflectionFee = 0;
    uint256 public liquidityFee = 0;
    
    uint256 private constant MAX_TAX = 2500; // Hard cap at 25%
    uint256 private _previousReflectionFee = reflectionFee;
    uint256 private _previousLiquidityFee = liquidityFee;
    
    // ============================================
    // Anti-Whale Configuration
    // ============================================
    uint256 public maxTransactionAmount = 10000000 * 10**18;
    uint256 public maxWalletAmount = 20000000 * 10**18;
    bool public antiWhaleEnabled = true;
    
    // ============================================
    // Trade Cooldown Configuration
    // ============================================
    uint256 public tradeCooldownTime = 30; // in seconds
    mapping(address => uint256) private _lastTradeTime;
    
    // ============================================
    // Wallet Configuration
    // ============================================
    address public marketingWallet = 0x655F76440B5Eb86b3bc40Fa710a84E17a27EF8a3;
    
    // ============================================
    // DEX Configuration
    // ============================================
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private numTokensSellToAddToLiquidity;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    // ============================================
    // Mappings
    // ============================================
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public isBlacklisted;
    address[] private _excluded;
    
    // ============================================
    // Events
    // ============================================
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event TaxUpdated(uint256 buyTax, uint256 sellTax, uint256 transferTax);
    event MarketingWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event AntiWhaleUpdated(uint256 maxTx, uint256 maxWallet, bool enabled);
    event TokenPaused(bool isPaused);
    event Burn(address indexed burner, uint256 amount);
    event Airdrop(address indexed sender, uint256 totalRecipients, uint256 totalAmount);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event TradeCooldownUpdated(bool enabled, uint256 cooldownTime);
    event EarlySellPenaltyUpdated(bool enabled, uint256 duration, uint256 tax);
    event VestingClaimed(address indexed beneficiary, uint256 amount);
    event StakingPoolUpdated(address indexed pool, bool authorized);
    
    // ============================================
    // Modifiers
    // ============================================
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // ============================================
    // Constructor
    // ============================================
    constructor() {
        _setOwner(0x655F76440B5Eb86b3bc40Fa710a84E17a27EF8a3);
        _rOwned[owner()] = _rTotal;
        
        numTokensSellToAddToLiquidity = _tTotal.mul(5).div(10000); // 0.05%
        
        // Set up DEX router and create pair
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        automatedMarketMakerPairs[uniswapV2Pair] = true;
        
        // Exclude from fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        
        // Exclude from limits
        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[marketingWallet] = true;
        _isExcludedFromLimits[uniswapV2Pair] = true;
        
        // Initialize EIP-2612 Domain Separator
        if (permitEnabled) {
            DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(_name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
        }
        
        // Lock vesting tokens
        if (vestingEnabled && vestingAmount > 0 && vestingBeneficiary != address(0)) {
            // The vesting amount is held by the contract itself
            // Transfer vesting tokens from owner to contract
            uint256 vestingRAmount = vestingAmount.mul(_getRate());
            _rOwned[owner()] = _rOwned[owner()].sub(vestingRAmount);
            _rOwned[address(this)] = _rOwned[address(this)].add(vestingRAmount);
            emit Transfer(owner(), address(this), vestingAmount);
        }
        
        emit Transfer(address(0), owner(), _tTotal);
    }

    // ============================================
    // ERC20 Standard Functions
    // ============================================
    
    /// @notice Returns the token name.
    function name() public view returns (string memory) { return _name; }
    
    /// @notice Returns the token symbol.
    function symbol() public view returns (string memory) { return _symbol; }
    
    /// @notice Returns the token decimals.
    function decimals() public view returns (uint8) { return _decimals; }
    
    /// @notice Returns the total token supply.
    function totalSupply() public view override returns (uint256) { return _tTotal; }
    
    /// @notice Returns the balance of an account.
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    /// @notice Transfers tokens to a recipient.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    /// @notice Returns the allowance of a spender for an owner.
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    
    /// @notice Approves a spender to spend tokens.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /// @notice Transfers tokens from sender to recipient using allowance.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    /// @notice Increases the allowance of a spender.
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    /// @notice Decreases the allowance of a spender.
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    // ============================================
    // Reflection Functions
    // ============================================
    
    /// @notice Checks if an account is excluded from reflection rewards.
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    /// @notice Returns total fees collected.
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    /// @notice Excludes an account from reflection rewards. Owner only.
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    
    /// @notice Includes an account in reflection rewards. Owner only.
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    // ============================================
    // Fee & Limit Management
    // ============================================
    
    /// @notice Excludes an account from fees. Owner only.
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /// @notice Includes an account in fees. Owner only.
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    /// @notice Checks if an account is excluded from fees.
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    /// @notice Excludes or includes an account from limits. Owner only.
    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        _isExcludedFromLimits[account] = excluded;
    }
    
    /// @notice Checks if an account is excluded from limits.
    function isExcludedFromLimits(address account) public view returns(bool) {
        return _isExcludedFromLimits[account];
    }

    // ============================================
    // Owner Functions
    // ============================================
    
    /// @notice Sets buy, sell, and transfer taxes. Max 25% each.
    function setTaxes(uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) external onlyOwner {
        require(_buyTax <= MAX_TAX && _sellTax <= MAX_TAX && _transferTax <= MAX_TAX, "Tax max 25%");
        buyTax = _buyTax;
        sellTax = _sellTax;
        transferTax = _transferTax;
        emit TaxUpdated(_buyTax, _sellTax, _transferTax);
    }
    
    /// @notice Sets the reflection fee. Max 10%.
    function setReflectionFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Fee max 10%");
        reflectionFee = fee;
    }
    
    /// @notice Sets the liquidity fee. Max 10%.
    function setLiquidityFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Fee max 10%");
        liquidityFee = fee;
    }
    
    /// @notice Sets the marketing wallet address.
    function setMarketingWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid address");
        address oldWallet = marketingWallet;
        marketingWallet = _wallet;
        _isExcludedFromFee[_wallet] = true;
        _isExcludedFromLimits[_wallet] = true;
        emit MarketingWalletUpdated(oldWallet, _wallet);
    }
    
    /// @notice Configures anti-whale settings.
    function setAntiWhale(uint256 _maxTx, uint256 _maxWallet, bool _enabled) external onlyOwner {
        maxTransactionAmount = _maxTx;
        maxWalletAmount = _maxWallet;
        antiWhaleEnabled = _enabled;
        emit AntiWhaleUpdated(_maxTx, _maxWallet, _enabled);
    }
    
    /// @notice Enables or disables swap and liquify.
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    /// @notice Sets an address as an automated market maker pair.
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        automatedMarketMakerPairs[pair] = value;
        _isExcludedFromLimits[pair] = true;
    }
    
    /// @notice Pauses token transfers. Requires isPausable to be true.
    function pause() external onlyOwner {
        require(isPausable, "Pausing disabled");
        isPaused = true;
        emit TokenPaused(true);
    }
    
    /// @notice Unpauses token transfers.
    function unpause() external onlyOwner {
        require(isPausable, "Pausing disabled");
        isPaused = false;
        emit TokenPaused(false);
    }
    
    /// @notice Mints new tokens. Requires isMintable to be true.
    function mint(address to, uint256 amount) external onlyOwner {
        require(isMintable, "Minting disabled");
        _tTotal = _tTotal.add(amount);
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[to] = _rOwned[to].add(amount.mul(_getRate()));
        emit Transfer(address(0), to, amount);
    }
    
    /// @notice Burns tokens from the caller's balance.
    function burn(uint256 amount) public {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        require(_rOwned[_msgSender()] >= rAmount, "Burn amount exceeds balance");
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _tTotal = _tTotal.sub(amount);
        _rTotal = _rTotal.sub(rAmount);
        emit Transfer(_msgSender(), address(0), amount);
        emit Burn(_msgSender(), amount);
    }
    
    // ============================================
    // Blacklist Functions
    // ============================================
    
    /// @dev Internal function to check if an address can be blacklisted.
    function _canBlacklist(address account) private view returns (bool) {
        // Prevent blacklisting critical addresses
        if (account == owner()) return false;
        if (account == address(this)) return false;
        if (account == uniswapV2Pair) return false;
        if (account == address(uniswapV2Router)) return false;
        return true;
    }
    
    /// @notice Adds or removes an address from the blacklist. Owner only.
    /// @dev Cannot blacklist: owner, this contract, AMM pair, or router
    function setBlacklist(address account, bool blacklisted) external onlyOwner {
        require(blacklistEnabled, "Blacklist disabled");
        require(_canBlacklist(account), "Cannot blacklist this address");
        isBlacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }
    
    /// @notice Batch update blacklist status for multiple addresses.
    /// @dev Skips addresses that cannot be blacklisted
    function setBlacklistBatch(address[] calldata accounts, bool blacklisted) external onlyOwner {
        require(blacklistEnabled, "Blacklist disabled");
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_canBlacklist(accounts[i])) {
                isBlacklisted[accounts[i]] = blacklisted;
                emit BlacklistUpdated(accounts[i], blacklisted);
            }
        }
    }
    
    // ============================================
    // Trade Cooldown Functions
    // ============================================
    
    /// @notice Sets trade cooldown parameters.
    function setTradeCooldown(bool _enabled, uint256 _cooldownTime) external onlyOwner {
        require(_cooldownTime <= 600, "Cooldown max 10 minutes");
        tradeCooldownEnabled = _enabled;
        tradeCooldownTime = _cooldownTime;
        emit TradeCooldownUpdated(_enabled, _cooldownTime);
    }
    
    /// @notice Returns the time until an address can trade again.
    function getCooldownTimeRemaining(address account) public view returns (uint256) {
        if (!tradeCooldownEnabled) return 0;
        uint256 lastTrade = _lastTradeTime[account];
        if (block.timestamp >= lastTrade + tradeCooldownTime) return 0;
        return (lastTrade + tradeCooldownTime) - block.timestamp;
    }
    
    // ============================================
    // Early Sell Penalty Functions
    // ============================================
    
    /// @notice Configures early sell penalty parameters. Owner only.
    /// @param _enabled Whether the penalty is enabled
    /// @param _duration Duration (seconds) after purchase during which penalty applies
    /// @param _tax Additional tax in basis points (100 = 1%)
    function setEarlySellPenalty(bool _enabled, uint256 _duration, uint256 _tax) external onlyOwner {
        require(_duration <= 86400 * 7, "Max 7 days duration"); // Max 7 days
        require(_tax <= 2500, "Max 25% additional tax");
        earlySellPenaltyEnabled = _enabled;
        earlySellPenaltyDuration = _duration;
        earlySellPenaltyTax = _tax;
        emit EarlySellPenaltyUpdated(_enabled, _duration, _tax);
    }
    
    /// @notice Returns the time remaining for early sell penalty for an address.
    function getEarlySellPenaltyTimeRemaining(address account) public view returns (uint256) {
        if (!earlySellPenaltyEnabled) return 0;
        uint256 acquisitionTime = _tokenAcquisitionTime[account];
        if (acquisitionTime == 0) return 0;
        if (block.timestamp >= acquisitionTime + earlySellPenaltyDuration) return 0;
        return (acquisitionTime + earlySellPenaltyDuration) - block.timestamp;
    }
    
    // ============================================
    // Vesting Functions
    // ============================================
    
    /// @notice Claims vested tokens after the release time. Only beneficiary can call.
    function claimVesting() external nonReentrant {
        require(vestingEnabled, "Vesting not enabled");
        require(_msgSender() == vestingBeneficiary, "Not vesting beneficiary");
        require(!vestingClaimed, "Already claimed");
        require(block.timestamp >= vestingReleaseTime, "Vesting not yet released");
        require(vestingAmount > 0, "No vesting amount");
        
        vestingClaimed = true;
        
        // Transfer vested tokens from contract to beneficiary
        uint256 vestingRAmount = vestingAmount.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].sub(vestingRAmount);
        _rOwned[vestingBeneficiary] = _rOwned[vestingBeneficiary].add(vestingRAmount);
        
        emit Transfer(address(this), vestingBeneficiary, vestingAmount);
        emit VestingClaimed(vestingBeneficiary, vestingAmount);
    }
    
    /// @notice Returns the time remaining until vesting can be claimed.
    function getVestingTimeRemaining() public view returns (uint256) {
        if (!vestingEnabled || vestingClaimed) return 0;
        if (block.timestamp >= vestingReleaseTime) return 0;
        return vestingReleaseTime - block.timestamp;
    }
    
    /// @notice Returns vesting details.
    function getVestingInfo() external view returns (
        bool enabled,
        uint256 amount,
        uint256 releaseTime,
        address beneficiary,
        bool claimed,
        uint256 timeRemaining
    ) {
        return (
            vestingEnabled,
            vestingAmount,
            vestingReleaseTime,
            vestingBeneficiary,
            vestingClaimed,
            getVestingTimeRemaining()
        );
    }
    
    // ============================================
    // EIP-2612 Permit Functions
    // ============================================
    
    /// @notice Permits a spender to spend tokens using an off-chain signature (EIP-2612).
    /// @param owner_ The token owner
    /// @param spender The address to approve
    /// @param value The amount to approve
    /// @param deadline The deadline for the signature
    /// @param v The recovery byte of the signature
    /// @param r The first 32 bytes of the signature
    /// @param s The second 32 bytes of the signature
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(permitEnabled, "Permit not enabled");
        require(deadline >= block.timestamp, "Permit expired");
        
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner_,
                spender,
                value,
                nonces[owner_]++,
                deadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner_, "Invalid signature");
        
        _approve(owner_, spender, value);
    }
    
    // ============================================
    // Staking Support Functions
    // ============================================
    
    /// @notice Authorize or revoke a staking pool. Owner only.
    /// @dev Authorized pools are auto-excluded from fees and limits.
    function setStakingPool(address pool, bool authorized) external onlyOwner {
        require(stakingEnabled, "Staking not enabled");
        require(pool != address(0), "Invalid pool address");
        authorizedStakingPools[pool] = authorized;
        
        // Auto-exclude from fees and limits when authorizing
        if (authorized) {
            _isExcludedFromFee[pool] = true;
            _isExcludedFromLimits[pool] = true;
        }
        
        emit StakingPoolUpdated(pool, authorized);
    }
    
    /// @notice Check if address is an authorized staking pool.
    function isStakingPool(address pool) public view returns (bool) {
        return authorizedStakingPools[pool];
    }
    
    /// @notice Stake tokens on behalf of another user. Only callable by authorized staking pools.
    /// @dev This allows staking pools to pull tokens from users who have approved them.
    function stakeFor(address user, uint256 amount) external nonReentrant returns (bool) {
        require(stakingEnabled, "Staking not enabled");
        require(authorizedStakingPools[_msgSender()], "Not authorized staking pool");
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be > 0");
        
        _transfer(user, _msgSender(), amount);
        return true;
    }
    
    /// @notice Approve and stake tokens in one transaction for better UX.
    /// @dev Approves the pool and transfers tokens directly. Pool should credit the user with staked amount.
    function approveAndStake(address pool, uint256 amount) external nonReentrant returns (bool) {
        require(stakingEnabled, "Staking not enabled");
        require(authorizedStakingPools[pool], "Not authorized staking pool");
        require(amount > 0, "Amount must be > 0");
        
        // Approve the pool
        _approve(_msgSender(), pool, amount);
        
        // Transfer to pool (pool will handle the staking logic)
        _transfer(_msgSender(), pool, amount);
        
        return true;
    }
    
    // ============================================
    // Airdrop Function
    // ============================================
    
    /// @notice Airdrops tokens to multiple recipients in a single transaction.
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external nonReentrant {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length <= 200, "Max 200 recipients per batch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(balanceOf(_msgSender()) >= totalAmount, "Insufficient balance for airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0) && amounts[i] > 0) {
                _transfer(_msgSender(), recipients[i], amounts[i]);
            }
        }
        
        emit Airdrop(_msgSender(), recipients.length, totalAmount);
    }
    
    // ============================================
    // Withdrawal Functions (with Reentrancy Guard)
    // ============================================
    
    /// @notice Withdraws native currency from the contract. Owner only.
    function withdrawETH(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    /// @notice Withdraws ERC20 tokens from the contract. Owner only.
    function withdrawTokens(address token, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(this), "Cannot withdraw own tokens");
        IERC20(token).transfer(msg.sender, amount);
    }

    receive() external payable {}

    // ============================================
    // Internal Functions
    // ============================================
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = reflectionEnabled ? tAmount.mul(reflectionFee).div(10000) : 0;
        uint256 tLiquidity = autoLiquidityEnabled ? tAmount.mul(liquidityFee).div(10000) : 0;
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function removeAllFee() private {
        if(reflectionFee == 0 && liquidityFee == 0) return;
        _previousReflectionFee = reflectionFee;
        _previousLiquidityFee = liquidityFee;
        reflectionFee = 0;
        liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        reflectionFee = _previousReflectionFee;
        liquidityFee = _previousLiquidityFee;
    }
    
    function _approve(address owner_, address spender, uint256 amount) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Blacklist check
        if (blacklistEnabled) {
            require(!isBlacklisted[from] && !isBlacklisted[to], "Address is blacklisted");
        }
        
        // Check if paused
        if (isPaused && from != address(0) && to != address(0)) {
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Token transfers are paused");
        }
        
        // Trade cooldown check
        if (tradeCooldownEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) {
                require(block.timestamp >= _lastTradeTime[from] + tradeCooldownTime, "Trade cooldown active");
                require(block.timestamp >= _lastTradeTime[to] + tradeCooldownTime, "Trade cooldown active");
                _lastTradeTime[from] = block.timestamp;
                _lastTradeTime[to] = block.timestamp;
            }
        }
        
        // Anti-whale checks
        if (antiWhaleEnabled && !_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
            if (maxTransactionAmount > 0) {
                require(amount <= maxTransactionAmount, "Exceeds max transaction");
            }
            if (maxWalletAmount > 0 && !automatedMarketMakerPairs[to]) {
                require(balanceOf(to).add(amount) <= maxWalletAmount, "Exceeds max wallet");
            }
        }
        
        // Swap and liquify
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && !inSwapAndLiquify && !automatedMarketMakerPairs[from] && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        // Calculate tax
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        uint256 taxAmount = 0;
        
        if (takeFee) {
            if (automatedMarketMakerPairs[from] && buyTax > 0) {
                // Buying - record acquisition time
                taxAmount = amount.mul(buyTax).div(10000);
                _tokenAcquisitionTime[to] = block.timestamp;
            } else if (automatedMarketMakerPairs[to] && sellTax > 0) {
                // Selling - check for early sell penalty
                uint256 effectiveTax = sellTax;
                if (earlySellPenaltyEnabled && _tokenAcquisitionTime[from] > 0) {
                    if (block.timestamp < _tokenAcquisitionTime[from] + earlySellPenaltyDuration) {
                        effectiveTax = effectiveTax.add(earlySellPenaltyTax);
                        // Cap at max tax
                        if (effectiveTax > MAX_TAX) effectiveTax = MAX_TAX;
                    }
                }
                taxAmount = amount.mul(effectiveTax).div(10000);
            } else if (transferTax > 0) {
                taxAmount = amount.mul(transferTax).div(10000);
            }
        }
        
        // Apply tax (Checks-Effects-Interactions pattern)
        if (taxAmount > 0) {
            uint256 currentRate = _getRate();
            uint256 rTax = taxAmount.mul(currentRate);
            
            // Effects first
            _rOwned[from] = _rOwned[from].sub(rTax);
            _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rTax);
            
            if (_isExcluded[from]) _tOwned[from] = _tOwned[from].sub(taxAmount);
            if (_isExcluded[marketingWallet]) _tOwned[marketingWallet] = _tOwned[marketingWallet].add(taxAmount);
            
            emit Transfer(from, marketingWallet, taxAmount);
            amount = amount.sub(taxAmount);
        }
        
        // Token transfer with reflection
        if (!takeFee) removeAllFee();
        _tokenTransfer(from, to, amount);
        if (!takeFee) restoreAllFee();
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        if (reflectionEnabled) _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        if (reflectionEnabled) _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        if (reflectionEnabled) _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        if (reflectionEnabled) _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
}
