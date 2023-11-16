// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { MutexLock } from "../../base/MutexLock.sol";
import { Unauthorized, UnsupportedOperation } from "../../base/ErrorMessages.sol";

import { SafeERC20 } from "../../libraries/SafeERC20.sol";

import { ITokenAdapter } from "../../interfaces/ITokenAdapter.sol";
import { IWETH9 } from "../../interfaces/external/IWETH9.sol";
import { IswETH } from "./../../interfaces/external/swell/IswETH.sol";
import { IPool as IMaverickPool } from "../../interfaces/external/maverick/IPool.sol";
import { ISwapRouter as IMaverickSwapRouter } from "../../interfaces/external/maverick/ISwapRouter.sol";

struct InitializationParams {
    address zeroliquid;
    address token;
    address underlyingToken;
    address maverickPool;
    address maverickRouter;
}

contract SwETHAdapter is ITokenAdapter, MutexLock {
    string public override version = "1.0.0";

    address public immutable zeroliquid;
    address public immutable override token;
    address public immutable override underlyingToken;
    address public immutable maverickPool;
    address public immutable maverickRouter;

    constructor(InitializationParams memory params) {
        zeroliquid = params.zeroliquid;
        token = params.token;
        underlyingToken = params.underlyingToken;
        maverickPool = params.maverickPool;
        maverickRouter = params.maverickRouter;
    }

    /// @dev Checks that the message sender is the zeroliquid contract that the adapter is bound to.
    modifier onlyZeroLiquid() {
        if (msg.sender != zeroliquid) {
            revert Unauthorized("Not ZeroLiquid");
        }
        _;
    }

    receive() external payable {
        if (msg.sender != underlyingToken) {
            revert Unauthorized("Payments only permitted from WETH");
        }
    }

    /// @inheritdoc ITokenAdapter
    function price() external view returns (uint256) {
        return IswETH(token).swETHToETHRate();
    }

    /// @inheritdoc ITokenAdapter
    function wrap(uint256 amount, address recipient) external onlyZeroLiquid returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);

        // Unwrap the WETH into ETH.
        IWETH9(underlyingToken).withdraw(amount);

        uint256 startingSwETHBalance = IERC20(token).balanceOf(address(this));
        IswETH(token).deposit{ value: amount }();
        uint256 mintedSwETH = IERC20(token).balanceOf(address(this)) - startingSwETHBalance;

        // Transfer the minted wstETH to the recipient.
        SafeERC20.safeTransfer(token, recipient, mintedSwETH);

        return mintedSwETH;
    }

    // @inheritdoc ITokenAdapter
    function unwrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        SafeERC20.safeApprove(token, maverickRouter, amount);

        IMaverickSwapRouter.ExactInputSingleParams memory params = IMaverickSwapRouter.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: underlyingToken,
            pool: IMaverickPool(maverickPool),
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitD18: 0
        });

        uint256 receivedWETH = IMaverickSwapRouter(maverickRouter).exactInputSingle(params);

        // Transfer the tokens to the recipient.
        SafeERC20.safeTransfer(underlyingToken, recipient, receivedWETH);

        return receivedWETH;
    }
}
