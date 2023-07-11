pragma solidity >=0.5.0;

/// @title  IWETHGateway
/// @author ZeroLiquid
interface IWETHGateway {
    /// @notice Refreshes the wrapped ethereum ERC20 approval for an zeroliquid contract.
    ///
    /// @param zeroliquid The address of the zeroliquid to refresh the allowance for.
    function refreshAllowance(address zeroliquid) external;

    /// @notice Takes ethereum, converts it to wrapped ethereum, and then deposits it into an zeroliquid.
    ///
    /// See [IZeroLiquidActions.depositUnderlying](./zeroliquid/IZeroLiquidActions.md#depositunderlying) for more
    /// details.
    ///
    /// @param zeroliquid        The address of the zeroliquid to deposit wrapped ethereum into.
    /// @param yieldToken       The yield token to deposit the wrapped ethereum as.
    /// @param amount           The amount of ethereum to deposit.
    /// @param recipient        The address which will receive the deposited yield tokens.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be deposited to `recipient`.
    function depositUnderlying(
        address zeroliquid,
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    )
        external
        payable;

    /// @notice Withdraws a wrapped ethereum based yield token from an zeroliquid, converts it to ethereum, and then
    ///         transfers it to the recipient.
    ///
    /// A withdraw approval on the zeroliquid is required for this call to succeed.
    ///
    /// See [IZeroLiquidActions.withdrawUnderlying](./zeroliquid/IZeroLiquidActions.md#withdrawunderlying) for more
    /// details.
    ///
    /// @param zeroliquid        The address of the zeroliquid to withdraw wrapped ethereum from.
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The amount of shares to withdraw.
    /// @param recipient        The address which will receive the ethereum.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to
    /// `recipient`.
    function withdrawUnderlying(
        address zeroliquid,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    )
        external;
}
