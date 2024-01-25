// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { SafeERC20 } from "./libraries/SafeERC20.sol";

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IWETH9 } from "./interfaces/external/IWETH9.sol";

import { Unauthorized, IllegalState, IllegalArgument } from "./base/ErrorMessages.sol";

/// @title  IZeroLiquid
/// @author ZeroLiquid
interface IZeroLiquid {
    /// @notice Deposit a yield token into a user's account.
    ///
    /// @notice An approval must be set for `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    ///
    /// @notice **_NOTE:_** When depositing, the `ZeroLiquid` contract must have **allowance()** to spend funds on
    /// behalf of **msg.sender** for at least **amount** of the **yieldToken** being deposited.  This can be done via
    /// the standard `ERC20.approve()` method.
    ///
    /// @param yieldToken The yield-token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The owner of the account that will receive the resulting shares.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function deposit(address yieldToken, uint256 amount, address recipient) external returns (uint256 sharesIssued);
}

/// @title  IStableSwap
/// @author Curve Finance
interface IStableSwap {
    // Gets the address of the token specified by `index` param on curve pool contract
    function coins(uint256 index) external view returns (address);

    /// @notice Performs an exchange on curve pool contract
    ///
    /// @notice Requires approval of the token to be exchanged
    ///
    /// @param i Index specifing the sold token on curve pool contract
    /// @param j Index specifing the bought token on curve pool contract
    /// @param dx Amount of token to be exchanged
    /// @param minimumDy Minimum amount of bought token to be received
    function exchange(int128 i, int128 j, uint256 dx, uint256 minimumDy) external returns (uint256);
}

/// @title  IAggregationRouterV5
/// @author 1inch Aggregator
interface IAggregationRouterV5 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /// @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See 1inch's tests for usage
    /// examples
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first
    /// swap of every token by leaving 1 wei on the contract.
    /// @param executor Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps
    function swap(
        address executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable;
}

/// @title  ZeroLiquidSwap
/// @author ZeroLiquid
/// @notice Used incase of depositing into ZeroLiquid using unsupported yield token.
/// Facilities depositing into ZeroLiquid by swapping altcoins/ETH on 1inch aggregator
/// for supported yield tokens.
contract ZeroLiquidSwap {
    IWETH9 public constant WETH = IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    address public immutable zeroliquid;
    address public immutable debtToken;
    // 1inch AggregationRouterV5 address
    address public immutable swapRouter;
    // zETH/WETH curve pool address
    address public immutable stableSwap;
    uint256 public immutable wethPoolIndex;
    uint256 public immutable zethPoolIndex;

    /// @notice Emits when a user swaps amount of `srcToken` specified by `srcAmount` to `dstToken` & deposits the
    /// `dstAmount` to `recipient`.
    ///
    /// @notice The `dstToken` will always be the supported yield token of ZeroLiquid protocol.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param srcToken     The address of `srctoken` that was swapped for `dstToken`.
    /// @param dstToken     The address of `dstToken` token that was deposited.
    /// @param srcAmount    The amount of `srcToken` that were swaped.
    /// @param dstAmount    The amount of `dstToken` that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event Deposit(
        address indexed sender,
        address indexed srcToken,
        address indexed dstToken,
        uint256 srcAmount,
        uint256 dstAmount,
        address recipient
    );

    constructor(
        address _zeroliquid,
        address _debtToken,
        address _swapRouter,
        address _stableSwap,
        uint256 _wethPoolIndex,
        uint256 _zethPoolIndex
    ) {
        if (
            _zeroliquid == address(0) || _debtToken == address(0) || _swapRouter == address(0)
                || _stableSwap == address(0)
        ) {
            revert IllegalArgument("Invalid Contract Address");
        }

        // Verify and make sure that the provided WETH index matches the curve pool WETH.
        if (IStableSwap(_stableSwap).coins(_wethPoolIndex) != address(WETH)) {
            revert IllegalArgument("Curve pool WETH token mismatch");
        }

        // Verify and make sure that the provided zETH index matches the curve pool zETH.
        if (IStableSwap(_stableSwap).coins(_zethPoolIndex) != _debtToken) {
            revert IllegalArgument("Curve pool zETH token mismatch");
        }

        zeroliquid = _zeroliquid;
        debtToken = _debtToken;
        swapRouter = _swapRouter;
        stableSwap = _stableSwap;
        wethPoolIndex = _wethPoolIndex;
        zethPoolIndex = _zethPoolIndex;
    }

    receive() external payable {
        if (IWETH9(msg.sender) != WETH) {
            revert Unauthorized("Payments only permitted from WETH");
        }
    }

    /// @notice Swaps altcoin or ETH to supported yield token and deposits it into zeroliquid.
    /// Uses 1inch AggregationRouterV5's swap() function for swapping
    ///
    /// @notice Emits Deposit event
    /// @notice An approval must be set for "srcToken" (except ETH) in swap description for amount >= desc.amount.
    ///
    /// @param recipient The owner of the account that will receive the resulting shares.
    /// @param executor Aggregation executor that executes calls described in `data`.
    /// @param desc Swap description.
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps.
    function deposit(
        address recipient,
        address executor,
        IAggregationRouterV5.SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    )
        external
        payable
    {
        uint256 receivedAmount;

        if (desc.srcToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && desc.amount == msg.value) {
            uint256 startingAmount = IERC20(desc.dstToken).balanceOf(address(this));
            IAggregationRouterV5(swapRouter).swap{ value: msg.value }(executor, desc, permit, data);
            receivedAmount = IERC20(desc.dstToken).balanceOf(address(this)) - startingAmount;

            SafeERC20.safeApprove(desc.dstToken, zeroliquid, receivedAmount);
            IZeroLiquid(zeroliquid).deposit(desc.dstToken, receivedAmount, recipient);
        } else {
            SafeERC20.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);

            SafeERC20.safeApprove(desc.srcToken, swapRouter, desc.amount);
            uint256 startingAmount = IERC20(desc.dstToken).balanceOf(address(this));
            IAggregationRouterV5(swapRouter).swap{ value: 0 }(executor, desc, permit, data);
            receivedAmount = IERC20(desc.dstToken).balanceOf(address(this)) - startingAmount;

            SafeERC20.safeApprove(desc.dstToken, zeroliquid, receivedAmount);
            IZeroLiquid(zeroliquid).deposit(desc.dstToken, receivedAmount, recipient);
        }

        emit Deposit(msg.sender, desc.srcToken, desc.dstToken, desc.amount, receivedAmount, recipient);
    }

    /// @notice Swaps debt token on curve for WETH, unwraps it send it to the owner
    /// @notice Requires debt token's approval
    ///
    /// @param amount Amount of debt token to swap
    /// @param minimumAmountOut Minimum amount of received token i.e. WETH
    ///
    /// @return receivedWETH Amount of ETH returned
    function swap(uint256 amount, uint256 minimumAmountOut) external returns (uint256) {
        SafeERC20.safeTransferFrom(debtToken, msg.sender, address(this), amount);

        SafeERC20.safeApprove(debtToken, stableSwap, amount);
        uint256 receivedWETH = IStableSwap(stableSwap).exchange(
            int128(uint128(zethPoolIndex)), int128(uint128(wethPoolIndex)), amount, minimumAmountOut
        );

        WETH.withdraw(receivedWETH);

        (bool success,) = msg.sender.call{ value: receivedWETH }(new bytes(0));
        if (!success) {
            revert IllegalState("Unsuccessful Transfer");
        }

        return receivedWETH;
    }
}
