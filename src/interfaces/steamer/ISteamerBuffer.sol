// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./ISteamer.sol";
import "../IZeroLiquid.sol";
import "../IERC20TokenReceiver.sol";

/// @title  ISteamerBuffer
/// @author ZeroLiquid
interface ISteamerBuffer is IERC20TokenReceiver {
    /// @notice Parameters used to define a given weighting schema.
    ///
    /// Weighting schemas can be used to generally weight assets in relation to an action or actions that will be taken.
    /// In the SteamerBuffer, there are 2 actions that require weighting schemas: `burnCredit` and `depositFunds`.
    ///
    /// `burnCredit` uses a weighting schema that determines which yield-tokens are targeted when burning credit from
    /// the `Account` controlled by the SteamerBuffer, via the `ZeroLiquid.donate` function.
    ///
    /// `depositFunds` uses a weighting schema that determines which yield-tokens are targeted when depositing
    /// underlying-tokens into the ZeroLiquid.
    struct Weighting {
        // The weights of the tokens used by the schema.
        mapping(address => uint256) weights;
        // The tokens used by the schema.
        address[] tokens;
        // The total weight of the schema (sum of the token weights).
        uint256 totalWeight;
    }

    /// @notice Emitted when the zeroliquid is set.
    ///
    /// @param zeroliquid The address of the zeroliquid.
    event SetZeroLiquid(address zeroliquid);

    /// @notice Emitted when the amo is set.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amo             The address of the amo.
    event SetAmo(address underlyingToken, address amo);

    /// @notice Emitted when the the status of diverting to the amo is set for a given underlying token.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param divert          Whether or not to divert funds to the amo.
    event SetDivertToAmo(address underlyingToken, bool divert);

    /// @notice Emitted when an underlying token is registered.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param steamer      The address of the steamer for the underlying token.
    event RegisterAsset(address underlyingToken, address steamer);

    /// @notice Emitted when an underlying token's flow rate is updated.
    ///
    /// @param underlyingToken The underlying token.
    /// @param flowRate        The flow rate for the underlying token.
    event SetFlowRate(address underlyingToken, uint256 flowRate);

    /// @notice Emitted when the strategies are refreshed.
    event RefreshStrategies();

    /// @notice Emitted when a source is set.
    event SetSource(address source, bool flag);

    /// @notice Emitted when a steamer is updated.
    event SetSteamer(address underlyingToken, address steamer);

    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the total credit against the yield token held by the SteamerBuffer.
    ///
    /// @return The total credit.
    function getTotalCredit() external view returns (uint256);

    /// @notice Gets the total amount of underlying token that the SteamerBuffer controls in the ZeroLiquid.
    ///
    /// @param underlyingToken The underlying token to query.
    ///
    /// @return totalBuffered The total buffered.
    function getTotalUnderlyingBuffered(address underlyingToken) external view returns (uint256 totalBuffered);

    /// @notice Gets the total available flow for the underlying token
    ///
    /// The total available flow will be the lesser of `flowAvailable[token]` and `getTotalUnderlyingBuffered`.
    ///
    /// @param underlyingToken The underlying token to query.
    ///
    /// @return availableFlow The available flow.
    function getAvailableFlow(address underlyingToken) external view returns (uint256 availableFlow);

    /// @notice Gets the weight of the given weight type and token
    ///
    /// @param weightToken The type of weight to query.
    /// @param token       The weighted token.
    ///
    /// @return weight The weight of the token for the given weight type.
    function getWeight(address weightToken, address token) external view returns (uint256 weight);

    /// @notice Set a source of funds.
    ///
    /// @param source The target source.
    /// @param flag   The status to set for the target source.
    function setSource(address source, bool flag) external;

    /// @notice Set steamer by admin.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param underlyingToken The target underlying token to update.
    /// @param newSteamer   The new steamer for the target `underlyingToken`.
    function setSteamer(address underlyingToken, address newSteamer) external;

    /// @notice Set zeroliquid by admin.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param zeroliquid The new zeroliquid whose funds we are handling.
    function setZeroLiquid(address zeroliquid) external;

    /// @notice Set the address of the amo for a target underlying token.
    ///
    /// @param underlyingToken The address of the underlying token to set.
    /// @param amo The address of the underlying token's new amo.
    function setAmo(address underlyingToken, address amo) external;

    /// @notice Set whether or not to divert funds to the amo.
    ///
    /// @param underlyingToken The address of the underlying token to set.
    /// @param divert          Whether or not to divert underlying token to the amo.
    function setDivertToAmo(address underlyingToken, bool divert) external;

    /// @notice Refresh the yield-tokens in the SteamerBuffer.
    ///
    /// This requires a call anytime governance adds a new yield token to the zeroliquid.
    function refreshStrategies() external;

    /// @notice Registers an underlying-token.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param underlyingToken The underlying-token being registered.
    /// @param steamer      The steamer for the underlying-token.
    function registerAsset(address underlyingToken, address steamer) external;

    /// @notice Set flow rate of an underlying token.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param underlyingToken The underlying-token getting the flow rate set.
    /// @param flowRate        The new flow rate.
    function setFlowRate(address underlyingToken, uint256 flowRate) external;

    /// @notice Sets up a weighting schema.
    ///
    /// @param weightToken The name of the weighting schema.
    /// @param tokens      The yield-tokens to weight.
    /// @param weights     The weights of the yield tokens.
    function setWeights(address weightToken, address[] memory tokens, uint256[] memory weights) external;

    /// @notice Exchanges any available flow into the Steamer.
    ///
    /// This function is a way for the keeper to force funds to be exchanged into the Steamer.
    ///
    /// This function will revert if called by any account that is not a keeper. If there is not enough local balance of
    /// `underlyingToken` held by the SteamerBuffer any additional funds will be withdrawn from the ZeroLiquid by
    /// unwrapping `yieldToken`.
    ///
    /// @param underlyingToken The address of the underlying token to exchange.
    function exchange(address underlyingToken) external;

    /// @notice Flushes funds to the amo.
    ///
    /// @param underlyingToken The underlying token to flush.
    /// @param amount          The amount to flush.
    function flushToAmo(address underlyingToken, uint256 amount) external;

    /// @notice Burns available credit againt a yield token in the zeroliquid.
    ///
    function burnCredit() external;

    /// @notice Deposits local collateral into the zeroliquid
    ///
    /// @param underlyingToken The collateral to deposit.
    /// @param amount          The amount to deposit.
    function depositFunds(address underlyingToken, uint256 amount) external;

    /// @notice Withdraws collateral from the zeroliquid
    ///
    /// This function reverts if:
    /// - The caller is not the steamer.
    /// - There is not enough flow available to fulfill the request.
    /// - There is not enough underlying collateral in the zeroliquid controlled by the buffer to fulfil the request.
    ///
    /// @param underlyingToken The underlying token to withdraw.
    /// @param amount          The amount to withdraw.
    /// @param recipient       The account receiving the withdrawn funds.
    function withdraw(address underlyingToken, uint256 amount, address recipient) external;

    /// @notice Withdraws collateral from the zeroliquid
    ///
    /// @param yieldToken       The yield token to withdraw.
    /// @param shares           The amount of ZeroLiquid shares to withdraw.
    /// @param minimumAmountOut The minimum amount of underlying tokens needed to be received as a result of unwrapping
    /// the yield tokens.
    function withdrawFromZeroLiquid(address yieldToken, uint256 shares, uint256 minimumAmountOut) external;
}
