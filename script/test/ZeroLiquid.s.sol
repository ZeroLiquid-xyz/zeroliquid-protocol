// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";
import "forge-std/console2.sol";
import "forge-std/console.sol";

import {
    WstETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/lido/WstETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IChainlinkOracle } from "./../../src/interfaces/external/chainlink/IChainlinkOracle.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "./../../src/interfaces/external/curve/IStableSwap2Pool.sol";
import { IStETH } from "./../../src/interfaces/external/lido/IStETH.sol";
import { IWstETH } from "./../../src/interfaces/external/lido/IWstETH.sol";
import { ITokenAdapter } from "./../../src/interfaces/ITokenAdapter.sol";
import { IZeroLiquidAdminActions } from "./../../src/interfaces/zeroliquid/IZeroLiquidAdminActions.sol";
import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { ISteamerBuffer } from "./../../src/interfaces/steamer/ISteamerBuffer.sol";
import { ISteamer } from "./../../src/interfaces/steamer/ISteamer.sol";
import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";
import { IChainlinkOracle } from "./../../src/interfaces/external/chainlink/IChainlinkOracle.sol";

contract ZeroLiquidScript is Script {
    uint256 constant BPS = 10_000;
    address constant admin = 0x3f5E68DEae10e1Ce34A8Df42F1E2FD2f6B731B91;
    address constant user_1 = 0x758ae03800AA562399BFe5cffbad98Bfc66776C8;
    address constant user_1_testnet = 0xC3ce2F6209036c43242E7e019A3128d2E94c1D31;
    address constant user_2 = 0x9283fD7e72a89b2fBF83fbd0f8EC9DDaCCc629fA;
    address constant user_3 = 0xE980Bf091dc9F0c054c3C9a13a3216D4ff29Aee4;
    address constant user_s = 0xf0bc96D1A267Ab9d6A952Cbb627AAE4bf0013763;
    address constant user_m = 0x6bF26E0CF77D51a08268785A957f98223964B746;
    address constant user_m_2 = 0xEb293A8Ae874c235cA6601Fb743012F41a8DfFa1;

    // address constant user_b = 0xb008B170bebD2C9560803B96FC2954161E2946C2;

    // IStETH constant stETH = IStETH(0xCa757555fA05Ed1F228dE4938A9921C2e3eAAfF9);
    // IWstETH constant wstETH = IWstETH(0xf9D689e2aBaC0f531360d16D129fA11B331Dc2e0);
    address constant unshETH = 0xD99351D32EC8C067Ea1c8Bbfb41bD27836E871ce;
    IWETH9 constant weth = IWETH9(0x8dF8C7506708BE301340B25fC4d928F7829F68E1);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0x8566168D2C970EA21c46b9BB3dA8BCDAF7f9b0c3);

    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x947d01482466729756eA55FD0825011A94B039A1);

    ISteamerBuffer constant steamerBuffer = ISteamerBuffer(0x049C3e15E1E465b026ADE3dA5Be68ef6F94aC705);
    ISteamer constant steamer = ISteamer(0x4dBcCbC33fF250BC8740127FcF988a2805733df9);
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xAe482AaBB145c7492fDCaE7FAebdf3519B91a55a);
    ITokenAdapter constant unshETHAdapter = ITokenAdapter(0xc7F20d8Ea6bdEccD28FBA953e7E29d696038e400);
    // IStableSwap2Pool constant zETHCurvePool = IStableSwap2Pool(0x270F4F3D69BB8df86EFf01a9eaE81496F0eb04dd);
    IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_USER_1");
        vm.startBroadcast(deployerPrivateKey);

        // SEND USING ADMIN
        // zeroliquid.addUnderlyingToken(
        //     address(weth),
        //     IZeroLiquidAdminActions.UnderlyingTokenConfig({
        //         repayLimitMinimum: 1,
        //         repayLimitMaximum: 10e18,
        //         repayLimitBlocks: 10,
        //         liquidationLimitMinimum: 1,
        //         liquidationLimitMaximum: 100e18,
        //         liquidationLimitBlocks: 10
        //     })
        // );
        // zeroliquid.setUnderlyingTokenEnabled(address(weth), true);

        // // zeroliquid.configureLiquidationLimit(address(weth), 100e18, 10);

        // zeroliquid.addYieldToken(
        //     unshETH,
        //     IZeroLiquidAdminActions.YieldTokenConfig({
        //         adapter: address(unshETHAdapter),
        //         maximumLoss: 1,
        //         maximumExpectedValue: 1000e18,
        //         creditUnlockBlocks: 1
        //     })
        // );
        // zeroliquid.setYieldTokenEnabled(unshETH, true);
        // zeroliquid.setTokenAdapter(unshETH, address(unshETHAdapter));
        // zeroliquid.setMaximumExpectedValue(unshETH, 500e18);

        // // zeroliquid.addDebtTokenPool(
        // //     IZeroLiquidAdminActions.DebtTokenPoolConfig({ethIndex: 0, debtTokenIndex: 1, pool:
        // // address(zETHCurvePool)})
        // // );

        // SEND USING OWNER OF ZEROLIQUID TOKEN
        // zeroliquidtoken.setWhitelist(address(zeroliquid), true);

        // SEND USING ADMIN
        // steamerBuffer.setZeroLiquid(address(zeroliquid));
        // steamerBuffer.setSteamer(address(weth), address(steamer));
        // zeroliquid.setKeeper(admin, true);
        // steamerBuffer.setFlowRate(address(weth), 50e18);
        // steamerBuffer.registerAsset(address(weth), address(steamer));

        // console.log("Price ==> %s", unshETHAdapter.price());
        // console.logInt(oracleEthUsd.latestAnswer());

        // console.log("minimumCollateralization ==> %s", zeroliquid.minimumCollateralization());

        // SafeERC20.safeApprove(address(weth), address(zeroliquid), 1e18);

        // IZeroLiquid.UnderlyingTokenParams memory params = zeroliquid.getUnderlyingTokenParameters(address(weth));
        // console.log("conversionFactor ==> %s", params.conversionFactor);
        // console.log("minimumCollateralization ==> %s", zeroliquid.minimumCollateralization());

        // console.log("yieldTokenPrice ==> %s", yieldTokenPrice(address(wstETH)));
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(1e18, address(wstETH)));
        // zeroliquid.depositUnderlying(unshETH, 1e18, user_1_testnet, minimumAmountOut(1e18, address(unshETH)));
        // zeroliquid.deposit(address(wstETH), 3e17, user_2);

        // (int256 debt_1,) = zeroliquid.accounts(user_1);
        // console.logInt(debt_1);
        // (uint256 shares, uint256 lastAccruedWeight) = zeroliquid.positions(user_1, address(wstETH));
        // console.log("Shares ==> %s, LastAccruedWeight ==> %s", shares, lastAccruedWeight);
        // uint256 amountUnderlyingToken = zeroliquid.convertSharesToUnderlyingTokens(address(wstETH), shares);
        // console.log("amountUnderlyingToken ==> %s", amountUnderlyingToken);
        // shares));
        // zeroliquid.mint(100_000_000_000_000_000, user_1_testnet);

        // (int256 debt_1,) = zeroliquid.accounts(user_1);
        // (int256 debt_2,) = zeroliquid.accounts(user_2);
        // console.logInt(debt_1);
        // console.logInt(debt_2);
        // console.log("PRICE ==> %s", wstETHAdapter.price());

        // console.log("yieldTokenPrice ==> %s", yieldTokenPrice(address(wstETH)));
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(1.6e18, address(wstETH)));
        // zeroliquid.harvest(address(wstETH), minimumAmountOut(10e18, address(wstETH)));

        // (,, uint256 repayLimit) = zeroliquid.getRepayLimitInfo(address(weth));
        // console.log("repayLimit", repayLimit);
        // SafeERC20.safeApprove(address(weth), address(zeroliquid), 1e17);
        // zeroliquid.repay(address(weth), 1e17, user_1_testnet);

        // zeroliquid.burn(5e17, user_1);

        // (,, uint256 liquidationLimit) = zeroliquid.getLiquidationLimitInfo(address(weth));
        // console.log("liquidationLimit ==> %s", liquidationLimit);

        // (uint256 shares_1_testnet,) = zeroliquid.positions(user_1_testnet, address(unshETH));
        // console2.log(shares_1_testnet);
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(5e17, address(wstETH)));
        // zeroliquid.liquidate(address(unshETH), 1e18, minimumAmountOut(1e18, address(unshETH)));

        // (uint256 shares_1_testnet,) = zeroliquid.positions(user_1_testnet, address(unshETH));
        // console2.log(shares_1_testnet);
        // (uint256 shares_2,) = zeroliquid.positions(user_2, address(wstETH));
        // console2.log(shares_2);
        // uint256 shares_user_1_testnet = 1_000_000_000_000_000_000;
        // zeroliquid.withdrawUnderlying(address(unshETH), shares_user_1_testnet, user_1_testnet,
        // shares_user_1_testnet);

        // =========================

        vm.stopBroadcast();
    }

    function minimumAmountOut(uint256 amount, address yieldToken) public view returns (uint256) {
        // No slippage accepted
        return amount / yieldTokenPrice(yieldToken);
    }

    function yieldTokenPrice(address yieldToken) internal view returns (uint256) {
        address adapter = zeroliquid.getYieldTokenParameters(yieldToken).adapter;

        return ITokenAdapter(adapter).price();
    }

    // function calculateBalance(uint256 debt, uint256 overCollateral, address underlyingToken) public returns (uint256)
    // {
    //     IZeroLiquid.UnderlyingTokenParams memory params = zeroliquid.getUnderlyingTokenParameters(underlyingToken);

    //     assert(params.conversionFactor != 0);

    //     // Conversion factor used to normalize debt token amount
    //     uint256 normalizedDebt = debt / params.conversionFactor;

    //     uint256 minimumCollateralization = zeroliquid.minimumCollateralization();

    //     uint256 fixedPointScalar = zeroliquid.FIXED_POINT_SCALAR();
    //     uint256 minimumCollateral = (minimumCollateralization * normalizedDebt) / fixedPointScalar;

    //     return minimumCollateral + overCollateral;
    // }
}
