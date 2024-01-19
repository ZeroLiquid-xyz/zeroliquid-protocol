// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { SafeERC20 } from "./libraries/SafeERC20.sol";

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IWETH9 } from "./interfaces/external/IWETH9.sol";

import { Unauthorized, IllegalState } from "./base/ErrorMessages.sol";

interface IZeroLiquid {
    function deposit(address yieldToken, uint256 amount, address recipient) external returns (uint256 sharesIssued);
    function mintFrom(address owner, uint256 amount, address recipient) external;
}

interface IStableSwap {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minimumDy) external returns (uint256);
}

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
/// for supported yield tokens & also facilities swapping of minted debt token to desired altcoins/ETH
contract ZeroLiquidSwap {
    IWETH9 public constant WETH = IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    address public immutable zeroliquid;
    address public immutable debtToken;
    // 1inch AggregationRouterV5 address
    address public immutable swapRouter;
    // zETH/WETH curve pool address
    address public immutable stableSwap;
    int128 public immutable wethPoolIndex;
    int128 public immutable zethPoolIndex;

    constructor(
        address _zeroliquid,
        address _debtToken,
        address _swapRouter,
        address _stableSwap,
        int128 _wethPoolIndex,
        int128 _zethPoolIndex
    ) {
        zeroliquid = _zeroliquid;
        debtToken = _debtToken;
        swapRouter = _swapRouter;
        stableSwap = _stableSwap;
        wethPoolIndex = _wethPoolIndex;
        zethPoolIndex = _zethPoolIndex;
    }

    receive() external payable {
        if (msg.sender != address(WETH)) {
            revert Unauthorized("Payments only permitted from WETH");
        }
    }

    /// @notice Swaps altcoin or ETH to supported yield token and deposits it into zeroliquid.
    /// Uses 1inch AggregationRouterV5's swap() function for swapping
    ///
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
        if (desc.srcToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && desc.amount == msg.value) {
            uint256 startingAmount = IERC20(desc.dstToken).balanceOf(address(this));
            IAggregationRouterV5(swapRouter).swap{ value: msg.value }(executor, desc, permit, data);
            uint256 receivedAmount = IERC20(desc.dstToken).balanceOf(address(this)) - startingAmount;

            SafeERC20.safeApprove(desc.dstToken, zeroliquid, receivedAmount);
            IZeroLiquid(zeroliquid).deposit(desc.dstToken, receivedAmount, recipient);
        } else {
            SafeERC20.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);

            SafeERC20.safeApprove(desc.srcToken, swapRouter, desc.amount);
            uint256 startingAmount = IERC20(desc.dstToken).balanceOf(address(this));
            IAggregationRouterV5(swapRouter).swap{ value: 0 }(executor, desc, permit, data);
            uint256 receivedAmount = IERC20(desc.dstToken).balanceOf(address(this)) - startingAmount;

            SafeERC20.safeApprove(desc.dstToken, zeroliquid, receivedAmount);
            IZeroLiquid(zeroliquid).deposit(desc.dstToken, receivedAmount, recipient);
        }
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
        uint256 receivedWETH = IStableSwap(stableSwap).exchange(zethPoolIndex, wethPoolIndex, amount, minimumAmountOut);

        WETH.withdraw(receivedWETH);

        (bool success,) = payable(msg.sender).call{ value: receivedWETH }("");
        if (!success) {
            revert IllegalState("Unsuccessful Transfer");
        }

        return receivedWETH;
    }
}
