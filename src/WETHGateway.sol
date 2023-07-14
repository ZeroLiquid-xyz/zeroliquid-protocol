// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./base/ErrorMessages.sol";
import "./interfaces/IZeroLiquid.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/IWETHGateway.sol";

/// @title  WETHGateway
/// @author ZeroLiquid
contract WETHGateway is IWETHGateway, Ownable {
    /// @notice The version.
    string public constant version = "1.0.0";

    /// @notice The wrapped ethereum contract.
    IWETH9 public immutable WETH;

    constructor(address weth) {
        WETH = IWETH9(weth);
    }

    /// @dev Allows for payments from the WETH contract.
    receive() external payable {
        if (IWETH9(msg.sender) != WETH) {
            revert Unauthorized("msg.sender is not WETH contract");
        }
    }

    /// @inheritdoc IWETHGateway
    function refreshAllowance(address zeroliquid) external onlyOwner {
        WETH.approve(zeroliquid, type(uint256).max);
    }

    /// @inheritdoc IWETHGateway
    function depositUnderlying(
        address zeroliquid,
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    )
        external
        payable
    {
        if (amount != msg.value) {
            revert IllegalArgument("Invalid deposit amount");
        }
        WETH.deposit{ value: msg.value }();
        IZeroLiquid(zeroliquid).depositUnderlying(yieldToken, amount, recipient, minimumAmountOut);
    }

    /// @inheritdoc IWETHGateway
    function withdrawUnderlying(
        address zeroliquid,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    )
        external
    {
        // Ensure that the underlying of the target yield token is in fact WETH
        IZeroLiquid.YieldTokenParams memory params = IZeroLiquid(zeroliquid).getYieldTokenParameters(yieldToken);
        if (params.underlyingToken != address(WETH)) {
            revert IllegalArgument("Token is not WETH contract");
        }

        IZeroLiquid(zeroliquid).withdrawUnderlyingFrom(msg.sender, yieldToken, shares, address(this), minimumAmountOut);

        uint256 amount = WETH.balanceOf(address(this));
        WETH.withdraw(amount);

        (bool success,) = recipient.call{ value: amount }(new bytes(0));
        if (!success) {
            revert IllegalState("Unsuccessful withdrawal");
        }
    }
}
