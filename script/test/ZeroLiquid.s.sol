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
import { IRETH } from "./../../src/interfaces/external/rocketpool/IRETH.sol";
import { ITokenAdapter } from "./../../src/interfaces/ITokenAdapter.sol";
import { IZeroLiquidAdminActions } from "./../../src/interfaces/zeroliquid/IZeroLiquidAdminActions.sol";
import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { ISteamerBuffer } from "./../../src/interfaces/steamer/ISteamerBuffer.sol";
import { ISteamer } from "./../../src/interfaces/steamer/ISteamer.sol";
import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";
import { IChainlinkOracle } from "./../../src/interfaces/external/chainlink/IChainlinkOracle.sol";

contract ZeroLiquidScript is Script {
    uint256 constant BPS = 10_000;
    address constant deployer = 0xf9175C0149F0B6CdDE5B68A744C6cCA93a0635f5;
    address constant admin = 0xbbfA751823F04c509346d14E3ec1182405ce2Dc4;
    address constant user_1 = 0x758ae03800AA562399BFe5cffbad98Bfc66776C8;

    IWETH9 constant weth = IWETH9(0xFb1cCC535677AcaED2E0dE6B03736E382216CB5A);
    IStETH constant stETH = IStETH(0x371F5875B42F4f3AC4195e487CF66Ef9BA0D781F);
    IWstETH constant wstETH = IWstETH(0xBB52CEB2cdbb2f31F7420dD5B8198d25E42750F1);
    IRETH constant rETH = IRETH(0xf26c213Ae58eD8f0Aa3A484Fd6d746b4C6287e49);
    // address constant unshETH = 0xD99351D32EC8C067Ea1c8Bbfb41bD27836E871ce;

    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0xD077c1b31b1eC141DF3D64cC240C92053998F7ab);
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xC818A4A3A82B07871B8Fea72579a9158272Ac052);
    ISteamer constant steamer = ISteamer(0xC53314020176077DFF5bd13B1Bd181091A17AA0f);
    ISteamerBuffer constant steamerBuffer = ISteamerBuffer(0x36D01326a68C254E416E25058C462dDd20FaA2f2);
    ITokenAdapter constant wstETHAdapter = ITokenAdapter(0xee7D2571cA2Eb847e13ec76231558B50d291218B);
    ITokenAdapter constant rETHAdapter = ITokenAdapter(0xB52c43BA2Bf5AF3e7ff6aB48d1bDaf6e7d4912d8);
    // ITokenAdapter constant unshETHAdapter = ITokenAdapter(0xc7F20d8Ea6bdEccD28FBA953e7E29d696038e400);

    // IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    // IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // SEND USING ADMIN
        // zeroliquid.addUnderlyingToken(
        //     address(weth),
        //     IZeroLiquidAdminActions.UnderlyingTokenConfig({
        //         repayLimitMinimum: 1,
        //         repayLimitMaximum: 2e18,
        //         repayLimitBlocks: 10,
        //         liquidationLimitMinimum: 1,
        //         liquidationLimitMaximum: 5e18,
        //         liquidationLimitBlocks: 10
        //     })
        // );
        // zeroliquid.setUnderlyingTokenEnabled(address(weth), true);

        // // zeroliquid.configureLiquidationLimit(address(weth), 100e18, 10);

        // zeroliquid.addYieldToken(
        //     address(wstETH),
        //     IZeroLiquidAdminActions.YieldTokenConfig({
        //         adapter: address(wstETHAdapter),
        //         maximumLoss: 1,
        //         maximumExpectedValue: 100e18,
        //         creditUnlockBlocks: 1
        //     })
        // );
        // zeroliquid.setYieldTokenEnabled(address(wstETH), true);
        // zeroliquid.setTokenAdapter(address(wstETH), address(wstETHAdapter));

        // zeroliquid.addYieldToken(
        //     address(rETH),
        //     IZeroLiquidAdminActions.YieldTokenConfig({
        //         adapter: address(rETHAdapter),
        //         maximumLoss: 1,
        //         maximumExpectedValue: 100e18,
        //         creditUnlockBlocks: 1
        //     })
        // );
        // zeroliquid.setYieldTokenEnabled(address(rETH), true);
        // zeroliquid.setTokenAdapter(address(rETH), address(rETHAdapter));

        // SEND USING OWNER OF ZEROLIQUID TOKEN
        // zeroliquidtoken.setWhitelist(address(zeroliquid), true);

        // SEND USING ADMIN
        // zeroliquid.setKeeper(admin, true);
        // steamerBuffer.setZeroLiquid(address(zeroliquid));
        // steamerBuffer.setSteamer(address(weth), address(steamer));
        // steamerBuffer.setFlowRate(address(weth), 5e18);
        // steamerBuffer.registerAsset(address(weth), address(steamer));

        // ############################################################################### VIEW TRANSACTIONS ###########
        // console.log("Price wstETH ==> %s", wstETHAdapter.price());
        // console.log("Price rETH ==> %s", rETHAdapter.price());

        // address[] memory underlyingTokens = zeroliquid.getSupportedUnderlyingTokens();
        // console.log("Supported Underlying Token ==> %s", underlyingTokens[0]);

        // address[] memory yieldtokens = zeroliquid.getSupportedYieldTokens();
        // console.log("Supported Yield Token ==> %s, %s, %s", yieldtokens[0], yieldtokens[1], yieldtokens.length);

        (int256 debt, address[] memory depositedTokens) = zeroliquid.accounts(deployer);
        console.logInt(debt);
        console.log("Deposited Token: %s", depositedTokens.length);

        (uint256 sharesWSTETH, uint256 lastAccruedWeightWSTETH) = zeroliquid.positions(deployer, address(wstETH));
        (uint256 sharesRETH, uint256 lastAccruedWeightRETH) = zeroliquid.positions(deployer, address(rETH));
        console.log("wstETH ==> SharesWSTETH: %s, LastAccruedWeightWSTETH: %s", sharesWSTETH, lastAccruedWeightWSTETH);
        console.log("wstETH ==> SharesRETH: %s, LastAccruedWeightRETH: %s", sharesRETH, lastAccruedWeightRETH);

        // #############################################################################################################

        // console.logInt(oracleEthUsd.latestAnswer());

        // console.log("minimumCollateralization ==> %s", zeroliquid.minimumCollateralization());

        // ############################################################################### SEND TRANSACTIONS ###########

        // DEPOSIT WSTETH
        // SafeERC20.safeApprove(address(wstETH), address(zeroliquid), 1e18);
        // zeroliquid.deposit(address(wstETH), 1e18, deployer);

        // DEPOSIT RETH
        // SafeERC20.safeApprove(address(rETH), address(zeroliquid), 1e18);
        // zeroliquid.deposit(address(rETH), 1e18, deployer);

        // MINT DEBT
        // zeroliquid.mint(2e17, deployer);

        // #############################################################################################################

        // IZeroLiquid.UnderlyingTokenParams memory params = zeroliquid.getUnderlyingTokenParameters(address(weth));
        // console.log("conversionFactor ==> %s", params.conversionFactor);
        // console.log("minimumCollateralization ==> %s", zeroliquid.minimumCollateralization());

        // console.log("yieldTokenPrice ==> %s", yieldTokenPrice(address(wstETH)));
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(1e18, address(wstETH)));
        // zeroliquid.depositUnderlying(unshETH, 1e18, user_1_testnet, minimumAmountOut(1e18, address(unshETH)));

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
