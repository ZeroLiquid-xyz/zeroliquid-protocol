// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { SafeERC20 } from "./libraries/SafeERC20.sol";

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IZeroLiquid {
    function deposit(address yieldToken, uint256 amount, address recipient) external returns (uint256 sharesIssued);
    function mintFrom(address owner, uint256 amount, address recipient) external;
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
/// @notice Facilities depositing into ZeroLiquid by swapping altcoins/ETH on 1inch aggregator
/// for supported yield tokens & also facilities swapping of minted debt token to desired altcoins/ETH
contract ZeroLiquidSwap {
    address public immutable zeroliquid;
    address public immutable debtToken;
    // 1inch AggregationRouterV5 address
    address public immutable swapRouter;

    constructor(address _zeroliquid, address _debtToken, address _swapRouter) {
        zeroliquid = _zeroliquid;
        debtToken = _debtToken;
        swapRouter = _swapRouter;
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

    /// @notice Mints debt token from zeroliquid & swaps them to the desired token described in swap description.
    /// Uses 1inch AggregationRouterV5's swap() function for swapping
    ///
    /// @notice Requires minting approval by calling "approveMint" function of ZeroLiquid.
    ///
    /// @param debtAmount Amount of debt user want to mint.
    /// @param executor Aggregation executor that executes calls described in `data`.
    /// @param desc Swap description.
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps.
    function swap(
        uint256 debtAmount,
        address executor,
        IAggregationRouterV5.SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    )
        external
    {
        IZeroLiquid(zeroliquid).mintFrom(msg.sender, debtAmount, address(this));

        // Give approval to 1inch's AggregationRouterV5
        SafeERC20.safeApprove(debtToken, swapRouter, debtAmount);
        IAggregationRouterV5(swapRouter).swap{ value: 0 }(executor, desc, permit, data);
    }
}
