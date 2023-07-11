pragma solidity >=0.5.0;

import "./zeroliquid/IZeroLiquidActions.sol";
import "./zeroliquid/IZeroLiquidAdminActions.sol";
import "./zeroliquid/IZeroLiquidErrors.sol";
import "./zeroliquid/IZeroLiquidImmutables.sol";
import "./zeroliquid/IZeroLiquidEvents.sol";
import "./zeroliquid/IZeroLiquidState.sol";

/// @title  IZeroLiquid
/// @author ZeroLiquid
interface IZeroLiquid is
    IZeroLiquidActions,
    IZeroLiquidAdminActions,
    IZeroLiquidErrors,
    IZeroLiquidImmutables,
    IZeroLiquidEvents,
    IZeroLiquidState
{ }
