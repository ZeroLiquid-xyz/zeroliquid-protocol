// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { IllegalArgument, Unauthorized } from "../../base/ErrorMessages.sol";
import { MutexLock } from "../../base/MutexLock.sol";

import { SafeERC20 } from "../../libraries/SafeERC20.sol";

import { ITokenAdapter } from "../../interfaces/ITokenAdapter.sol";
import { IWETH9 } from "../../interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "../../interfaces/external/curve/IStableSwap2Pool.sol";
import { IunshETHZap } from "./../../interfaces/external/unsheth/IunshETHZap.sol";
import { ILSDVault } from "./../../interfaces/external/unsheth/ILSDVault.sol";

struct InitializationParams {
    address zeroliquid;
    address lsdVault;
    address unshEthZap;
    address token;
    address underlyingToken;
    address curvePool;
    uint256 ethPoolIndex;
    uint256 unshEthPoolIndex;
}

contract UnshETHAdapter is ITokenAdapter, MutexLock {
    string public override version = "1.0.0";

    address public immutable zeroliquid;
    address public immutable lsdVault;
    address public immutable unshEthZap;
    address public immutable override token;
    address public immutable override underlyingToken;
    address public immutable curvePool;
    uint256 public immutable ethPoolIndex;
    uint256 public immutable unshEthPoolIndex;

    constructor(InitializationParams memory params) {
        zeroliquid = params.zeroliquid;
        lsdVault = params.lsdVault;
        unshEthZap = params.unshEthZap;
        token = params.token;
        underlyingToken = params.underlyingToken;
        curvePool = params.curvePool;
        ethPoolIndex = params.ethPoolIndex;
        unshEthPoolIndex = params.unshEthPoolIndex;

        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (IStableSwap2Pool(params.curvePool).coins(params.ethPoolIndex) != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }

        // Verify and make sure that the provided unshETH matches the curve pool unshETH.
        if (IStableSwap2Pool(params.curvePool).coins(params.unshEthPoolIndex) != params.token) {
            revert IllegalArgument("Curve pool unshETH token mismatch");
        }
    }

    /// @dev Checks that the message sender is the zeroliquid that the adapter is bound to.
    modifier onlyZeroLiquid() {
        if (msg.sender != zeroliquid) {
            revert Unauthorized("Not zeroliquid");
        }
        _;
    }

    receive() external payable {
        if (msg.sender != underlyingToken && msg.sender != curvePool) {
            revert Unauthorized("Payments only permitted from WETH or curve pool");
        }
    }

    /// @inheritdoc ITokenAdapter
    function price() external view returns (uint256) {
        return ILSDVault(lsdVault).stakedETHperunshETH();
    }

    /// @inheritdoc ITokenAdapter
    function wrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);

        // Unwrap the WETH into ETH.
        IWETH9(underlyingToken).withdraw(amount);

        // Wrap the ETH into unshETH.
        uint256 startingUnhETHBalance = IERC20(token).balanceOf(address(this));
        IunshETHZap(unshEthZap).mint_unsheth_with_eth{ value: amount }(0, 0);
        uint256 mintedUnshETH = IERC20(token).balanceOf(address(this)) - startingUnhETHBalance;

        // Transfer the minted unshETH to the recipient.
        SafeERC20.safeTransfer(token, recipient, mintedUnshETH);

        return mintedUnshETH;
    }

    // @inheritdoc ITokenAdapter
    function unwrap(uint256 amount, address recipient) external lock onlyZeroLiquid returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        SafeERC20.safeApprove(token, curvePool, amount);

        // Exchange the unshETH for ETH. We do not check the curve pool because it is an immutable
        // contract and we expect that its output is reliable.
        uint256 received = IStableSwap2Pool(curvePool).exchange(
            int128(uint128(unshEthPoolIndex)), // Why are we here, just to suffer?
            int128(uint128(ethPoolIndex)), //                       (╥﹏╥)
            amount,
            0 // <- Slippage is handled upstream
        );

        // Wrap the ETH that we received from the exchange.
        IWETH9(underlyingToken).deposit{ value: received }();

        // Transfer the tokens to the recipient.
        SafeERC20.safeTransfer(underlyingToken, recipient, received);

        return received;
    }
}
