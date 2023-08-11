// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import { AccessControl } from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import { Initializable } from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import "./base/Errors.sol";

import "./interfaces/IZeroLiquid.sol";
import "./interfaces/ITokenAdapter.sol";
import "./interfaces/steamer/ISteamerBuffer.sol";
import "./interfaces/steamer/ISteamer.sol";

import "./libraries/FixedPointMath.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/TokenUtils.sol";
import "./interfaces/IERC20TokenReceiver.sol";

/// @title  ISteamerBuffer
/// @author ZeroLiquid
///
/// @notice An interface contract to buffer funds between the ZeroLiquid and the Steamer
contract SteamerBuffer is ISteamerBuffer, AccessControl, Initializable {
    using FixedPointMath for FixedPointMath.Number;

    uint256 public constant BPS = 10_000;

    /// @notice The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @notice The identifier of the keeper role.
    bytes32 public constant KEEPER = keccak256("KEEPER");

    /// @inheritdoc ISteamerBuffer
    string public constant override version = "1.0.0";

    /// @notice The zeroliquid address.
    address public zeroliquid;

    /// @notice The public steamer address for each address.
    mapping(address => address) public steamer;

    /// @notice The flowRate for each address.
    mapping(address => uint256) public flowRate;

    /// @notice The last update timestamp gor the flowRate for each address.
    mapping(address => uint256) public lastFlowrateUpdate;

    /// @notice The amount of flow available per ERC20.
    mapping(address => uint256) public flowAvailable;

    /// @notice The yieldTokens of each underlying supported by the ZeroLiquid.
    mapping(address => address[]) public _yieldTokens;

    /// @notice The total amount of an underlying token that has been exchanged into the steamer, and has not been
    /// claimed.
    mapping(address => uint256) public currentExchanged;

    /// @notice The underlying-tokens registered in the SteamerBuffer.
    address[] public registeredUnderlyings;

    /// @notice The debt-token used by the SteamerBuffer.
    address public debtToken;

    /// @notice A mapping of weighting schemas to be used in actions taken on the ZeroLiquid (burn, deposit).
    mapping(address => Weighting) public weightings;

    /// @dev A mapping of addresses to denote permissioned sources of funds
    mapping(address => bool) public sources;

    /// @dev A mapping of addresses to their respective AMOs.
    mapping(address => address) public amos;

    /// @dev A mapping of underlying tokens to divert to the AMO.
    mapping(address => bool) public divertToAmo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer { }

    /// @dev Initialize the contract
    ///
    /// @param _admin     The governing address of the buffer.
    /// @param _debtToken The debt token minted by the ZeroLiquid and accepted by the Steamer.
    function initialize(address _admin, address _debtToken) external initializer {
        _setupRole(ADMIN, _admin);
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(KEEPER, ADMIN);
        debtToken = _debtToken;
    }

    /// @dev Only allows the steamer to call the modified function
    ///
    /// Reverts if the caller is not a correct steamer.
    ///
    /// @param underlyingToken the underlying token associated with the steamer.
    modifier onlySteamer(address underlyingToken) {
        if (msg.sender != steamer[underlyingToken]) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Only allows a governance-permissioned source to call the modified function
    ///
    /// Reverts if the caller is not a permissioned source.
    modifier onlySource() {
        if (!sources[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Only calls from the admin address are authorized to pass.
    modifier onlyAdmin() {
        if (!hasRole(ADMIN, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Only calls from a keeper address are authorized to pass.
    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    /// @inheritdoc ISteamerBuffer
    function getWeight(address weightToken, address token) external view override returns (uint256 weight) {
        return weightings[weightToken].weights[token];
    }

    /// @inheritdoc ISteamerBuffer
    function getAvailableFlow(address underlyingToken) external view override returns (uint256) {
        // total amount of collateral that the buffer controls in the zeroliquid
        uint256 totalUnderlyingBuffered = getTotalUnderlyingBuffered(underlyingToken);

        if (totalUnderlyingBuffered < flowAvailable[underlyingToken]) {
            return totalUnderlyingBuffered;
        } else {
            return flowAvailable[underlyingToken];
        }
    }

    /// @inheritdoc ISteamerBuffer
    function getTotalCredit(address yieldToken) public view override returns (uint256) {
        int256 debt = IZeroLiquid(zeroliquid).getAccount(address(this), yieldToken);
        return debt >= 0 ? 0 : SafeCast.toUint256(-debt);
    }

    /// @inheritdoc ISteamerBuffer
    function getTotalUnderlyingBuffered(address underlyingToken) public view override returns (uint256 totalBuffered) {
        totalBuffered = TokenUtils.safeBalanceOf(underlyingToken, address(this));
        for (uint256 i = 0; i < _yieldTokens[underlyingToken].length; ++i) {
            totalBuffered += _getTotalBuffered(_yieldTokens[underlyingToken][i]);
        }
    }

    /// @inheritdoc ISteamerBuffer
    function setWeights(
        address weightToken,
        address[] memory tokens,
        uint256[] memory weights
    )
        external
        override
        onlyAdmin
    {
        if (tokens.length != weights.length) {
            revert IllegalArgument();
        }
        Weighting storage weighting = weightings[weightToken];
        delete weighting.tokens;
        weighting.totalWeight = 0;
        for (uint256 i = 0; i < tokens.length; ++i) {
            address yieldToken = tokens[i];

            // For any weightToken that is not the debtToken, we want to verify that the yield-tokens being
            // set for the weight schema accept said weightToken as collateral.
            //
            // We don't want to do this check on the debtToken because it is only used in the burnCredit() function
            // and we want to be able to burn credit to any yield-token in the ZeroLiquid.
            if (weightToken != debtToken) {
                IZeroLiquid.YieldTokenParams memory params = IZeroLiquid(zeroliquid).getYieldTokenParameters(yieldToken);
                address underlyingToken = ITokenAdapter(params.adapter).underlyingToken();

                if (weightToken != underlyingToken) {
                    revert IllegalState();
                }
            }

            weighting.tokens.push(yieldToken);
            weighting.weights[yieldToken] = weights[i];
            weighting.totalWeight += weights[i];
        }
    }

    /// @inheritdoc ISteamerBuffer
    function setSource(address source, bool flag) external override onlyAdmin {
        if (sources[source] == flag) {
            revert IllegalArgument();
        }
        sources[source] = flag;
        emit SetSource(source, flag);
    }

    /// @inheritdoc ISteamerBuffer
    function setSteamer(address underlyingToken, address newSteamer) external override onlyAdmin {
        if (ISteamer(newSteamer).underlyingToken() != underlyingToken) {
            revert IllegalArgument();
        }
        steamer[underlyingToken] = newSteamer;
        emit SetSteamer(underlyingToken, newSteamer);
    }

    /// @inheritdoc ISteamerBuffer
    function setZeroLiquid(address _zeroliquid) external override onlyAdmin {
        sources[zeroliquid] = false;
        sources[_zeroliquid] = true;

        if (zeroliquid != address(0)) {
            for (uint256 i = 0; i < registeredUnderlyings.length; ++i) {
                TokenUtils.safeApprove(registeredUnderlyings[i], zeroliquid, 0);
            }
            TokenUtils.safeApprove(debtToken, zeroliquid, 0);
        }

        zeroliquid = _zeroliquid;
        for (uint256 i = 0; i < registeredUnderlyings.length; ++i) {
            TokenUtils.safeApprove(registeredUnderlyings[i], zeroliquid, type(uint256).max);
        }
        TokenUtils.safeApprove(debtToken, zeroliquid, type(uint256).max);

        emit SetZeroLiquid(zeroliquid);
    }

    /// @inheritdoc ISteamerBuffer
    function setAmo(address underlyingToken, address amo) external override onlyAdmin {
        amos[underlyingToken] = amo;
        emit SetAmo(underlyingToken, amo);
    }

    /// @inheritdoc ISteamerBuffer
    function setDivertToAmo(address underlyingToken, bool divert) external override onlyAdmin {
        divertToAmo[underlyingToken] = divert;
        emit SetDivertToAmo(underlyingToken, divert);
    }

    /// @inheritdoc ISteamerBuffer
    function registerAsset(address underlyingToken, address _steamer) external override onlyAdmin {
        if (!IZeroLiquid(zeroliquid).isSupportedUnderlyingToken(underlyingToken)) {
            revert IllegalState();
        }

        // only add to the array if not already contained in it
        for (uint256 i = 0; i < registeredUnderlyings.length; ++i) {
            if (registeredUnderlyings[i] == underlyingToken) {
                revert IllegalState();
            }
        }

        if (ISteamer(_steamer).underlyingToken() != underlyingToken) {
            revert IllegalArgument();
        }

        steamer[underlyingToken] = _steamer;
        registeredUnderlyings.push(underlyingToken);
        TokenUtils.safeApprove(underlyingToken, zeroliquid, type(uint256).max);
        emit RegisterAsset(underlyingToken, _steamer);
    }

    /// @inheritdoc ISteamerBuffer
    function setFlowRate(address underlyingToken, uint256 _flowRate) external override onlyAdmin {
        _exchange(underlyingToken);

        flowRate[underlyingToken] = _flowRate;
        emit SetFlowRate(underlyingToken, _flowRate);
    }

    /// @inheritdoc IERC20TokenReceiver
    function onERC20Received(address underlyingToken, uint256 amount) external override onlySource {
        if (divertToAmo[underlyingToken]) {
            _flushToAmo(underlyingToken, amount);
        } else {
            _updateFlow(underlyingToken);

            // total amount of collateral that the buffer controls in the zeroliquid
            uint256 localBalance = TokenUtils.safeBalanceOf(underlyingToken, address(this));

            // if there is not enough locally buffered collateral to meet the flow rate, exchange only the exchanged
            // amount
            if (localBalance < flowAvailable[underlyingToken]) {
                currentExchanged[underlyingToken] += amount;
                ISteamer(steamer[underlyingToken]).exchange(amount);
            } else {
                uint256 exchangeable = flowAvailable[underlyingToken] - currentExchanged[underlyingToken];
                currentExchanged[underlyingToken] += exchangeable;
                ISteamer(steamer[underlyingToken]).exchange(exchangeable);
            }
        }
    }

    /// @inheritdoc ISteamerBuffer
    function exchange(address underlyingToken) external override onlyKeeper {
        _exchange(underlyingToken);
    }

    /// @inheritdoc ISteamerBuffer
    function flushToAmo(address underlyingToken, uint256 amount) external override onlyKeeper {
        if (divertToAmo[underlyingToken]) {
            _flushToAmo(underlyingToken, amount);
        } else {
            revert IllegalState();
        }
    }

    /// @inheritdoc ISteamerBuffer
    function withdraw(
        address underlyingToken,
        uint256 amount,
        address recipient
    )
        external
        override
        onlySteamer(underlyingToken)
    {
        if (amount > flowAvailable[underlyingToken]) {
            revert IllegalArgument();
        }

        uint256 localBalance = TokenUtils.safeBalanceOf(underlyingToken, address(this));
        if (amount > localBalance) {
            revert IllegalArgument();
        }

        flowAvailable[underlyingToken] -= amount;
        currentExchanged[underlyingToken] -= amount;

        TokenUtils.safeTransfer(underlyingToken, recipient, amount);
    }

    /// @inheritdoc ISteamerBuffer
    function withdrawFromZeroLiquid(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    )
        external
        override
        onlyKeeper
    {
        IZeroLiquid(zeroliquid).withdrawUnderlying(yieldToken, shares, address(this), minimumAmountOut);
    }

    /// @inheritdoc ISteamerBuffer
    function refreshStrategies() public override {
        address[] memory supportedYieldTokens = IZeroLiquid(zeroliquid).getSupportedYieldTokens();
        address[] memory supportedUnderlyingTokens = IZeroLiquid(zeroliquid).getSupportedUnderlyingTokens();

        if (registeredUnderlyings.length != supportedUnderlyingTokens.length) {
            revert IllegalState();
        }

        // clear current strats
        for (uint256 j = 0; j < registeredUnderlyings.length; ++j) {
            delete _yieldTokens[registeredUnderlyings[j]];
        }

        uint256 numYTokens = supportedYieldTokens.length;
        for (uint256 i = 0; i < numYTokens; ++i) {
            address yieldToken = supportedYieldTokens[i];

            IZeroLiquid.YieldTokenParams memory params = IZeroLiquid(zeroliquid).getYieldTokenParameters(yieldToken);
            if (params.enabled) {
                _yieldTokens[params.underlyingToken].push(yieldToken);
            }
        }
        emit RefreshStrategies();
    }

    /// @inheritdoc ISteamerBuffer
    function burnCredit(address yieldToken) external override onlyKeeper {
        IZeroLiquid(zeroliquid).poke(address(this));
        uint256 credit = getTotalCredit(yieldToken);
        if (credit == 0) {
            revert IllegalState();
        }
        IZeroLiquid(zeroliquid).mint(yieldToken, credit, address(this));

        _zeroliquidAction(credit, debtToken, _zeroliquidDonate);
    }

    /// @inheritdoc ISteamerBuffer
    function depositFunds(address underlyingToken, uint256 amount) external override onlyKeeper {
        if (amount == 0) {
            revert IllegalArgument();
        }
        uint256 localBalance = TokenUtils.safeBalanceOf(underlyingToken, address(this));
        if (localBalance < amount) {
            revert IllegalArgument();
        }
        _updateFlow(underlyingToken);

        // Don't deposit exchanged funds into the ZeroLiquid.
        // Doing so puts those funds at risk, and could lead to users being unable to claim
        // their steamed funds in the event of a vault loss.
        if (localBalance - amount < currentExchanged[underlyingToken]) {
            revert IllegalState();
        }
        _zeroliquidAction(amount, underlyingToken, _zeroliquidDeposit);
    }

    /// @dev Gets the total value of the yield tokens in units of underlying tokens that this contract holds.
    ///
    /// @param yieldToken The address of the target yield token.
    /// @return totalBuffered The total amount buffered.
    function _getTotalBuffered(address yieldToken) internal view returns (uint256) {
        (uint256 balance,) = IZeroLiquid(zeroliquid).positions(address(this), yieldToken);
        IZeroLiquid.YieldTokenParams memory params = IZeroLiquid(zeroliquid).getYieldTokenParameters(yieldToken);
        uint256 tokensPerShare = IZeroLiquid(zeroliquid).getUnderlyingTokensPerShare(yieldToken);
        return (balance * tokensPerShare) / 10 ** params.decimals;
    }

    /// @dev Updates the available flow for a give underlying token.
    ///
    /// @param underlyingToken the underlying token whos flow is being updated.
    /// @return marginalFlow the marginal flow.
    function _updateFlow(address underlyingToken) internal returns (uint256) {
        // additional flow to be allocated based on flow rate
        uint256 marginalFlow = (block.timestamp - lastFlowrateUpdate[underlyingToken]) * flowRate[underlyingToken];
        flowAvailable[underlyingToken] += marginalFlow;
        lastFlowrateUpdate[underlyingToken] = block.timestamp;
        return marginalFlow;
    }

    /// @notice Runs an action on the ZeroLiquid according to a given weighting schema.
    ///
    /// This function gets a weighting schema defined under the `weightToken` key, and calls the target action
    /// with a weighted value of `amount` and the associated token.
    ///
    /// @param amount       The amount of funds to use in the action.
    /// @param weightToken  The key of the weighting schema to be used for the action.
    /// @param action       The action to be taken.
    function _zeroliquidAction(uint256 amount, address weightToken, function(address, uint256) action) internal {
        IZeroLiquid(zeroliquid).poke(address(this));

        Weighting storage weighting = weightings[weightToken];
        for (uint256 j = 0; j < weighting.tokens.length; ++j) {
            address token = weighting.tokens[j];
            uint256 actionAmt = (amount * weighting.weights[token]) / weighting.totalWeight;
            action(token, actionAmt);
        }
    }

    /// @notice Donate credit weight to a target yield-token by burning debt-tokens.
    ///
    /// @param token    The target yield-token.
    /// @param amount      The amount of debt-tokens to burn.
    function _zeroliquidDonate(address token, uint256 amount) internal {
        IZeroLiquid(zeroliquid).donate(token, amount);
    }

    /// @notice Deposits funds into the ZeroLiquid.
    ///
    /// @param token  The yield-token to deposit.
    /// @param amount The amount to deposit.
    function _zeroliquidDeposit(address token, uint256 amount) internal {
        IZeroLiquid(zeroliquid).depositUnderlying(token, amount, address(this), 0);
    }

    /// @notice Withdraws funds from the ZeroLiquid.
    ///
    /// @param token            The yield-token to withdraw.
    /// @param amountUnderlying The amount of underlying to withdraw.
    function _zeroliquidWithdraw(address token, uint256 amountUnderlying) internal {
        uint8 decimals = TokenUtils.expectDecimals(token);
        uint256 pricePerShare = IZeroLiquid(zeroliquid).getUnderlyingTokensPerShare(token);
        uint256 wantShares = amountUnderlying * 10 ** decimals / pricePerShare;
        (uint256 availableShares, uint256 lastAccruedWeight) = IZeroLiquid(zeroliquid).positions(address(this), token);
        if (wantShares > availableShares) {
            wantShares = availableShares;
        }
        // Allow 1% slippage
        uint256 minimumAmountOut = amountUnderlying - amountUnderlying * 100 / BPS;
        if (wantShares > 0) {
            IZeroLiquid(zeroliquid).withdrawUnderlying(token, wantShares, address(this), minimumAmountOut);
        }
    }

    /// @notice Pull necessary funds from the ZeroLiquid and exchange them.
    ///
    /// @param underlyingToken The underlying-token to exchange.
    function _exchange(address underlyingToken) internal {
        _updateFlow(underlyingToken);

        uint256 totalUnderlyingBuffered = getTotalUnderlyingBuffered(underlyingToken);
        uint256 initialLocalBalance = TokenUtils.safeBalanceOf(underlyingToken, address(this));
        uint256 want = 0;
        // Here we assume the invariant underlyingToken.balanceOf(address(this)) >= currentExchanged[underlyingToken].
        if (totalUnderlyingBuffered < flowAvailable[underlyingToken]) {
            // Pull the rest of the funds from the ZeroLiquid.
            want = totalUnderlyingBuffered - initialLocalBalance;
        } else if (initialLocalBalance < flowAvailable[underlyingToken]) {
            // totalUnderlyingBuffered > flowAvailable so we have funds available to pull.
            want = flowAvailable[underlyingToken] - initialLocalBalance;
        }

        if (want > 0) {
            _zeroliquidAction(want, underlyingToken, _zeroliquidWithdraw);
        }

        uint256 localBalance = TokenUtils.safeBalanceOf(underlyingToken, address(this));
        uint256 exchangeDelta = 0;
        if (localBalance > flowAvailable[underlyingToken]) {
            exchangeDelta = flowAvailable[underlyingToken] - currentExchanged[underlyingToken];
        } else {
            exchangeDelta = localBalance - currentExchanged[underlyingToken];
        }

        if (exchangeDelta > 0) {
            currentExchanged[underlyingToken] += exchangeDelta;
            ISteamer(steamer[underlyingToken]).exchange(exchangeDelta);
        }
    }

    /// @notice Flush funds to the amo.
    ///
    /// @param underlyingToken The underlyingToken to flush.
    /// @param amount          The amount to flush.
    function _flushToAmo(address underlyingToken, uint256 amount) internal {
        TokenUtils.safeTransfer(underlyingToken, amos[underlyingToken], amount);
        IERC20TokenReceiver(amos[underlyingToken]).onERC20Received(underlyingToken, amount);
    }
}
