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
import { RocketDepositPoolInterface } from "src/test/mocks/RocketDepositPoolInterface.sol";
import { SteamerBuffer } from "src/SteamerBuffer.sol";
import { IWETHGateway } from "src/interfaces/IWETHGateway.sol";

contract ZeroLiquidScript is Script {
    uint256 constant BPS = 10_000;
    address constant deployer = 0xf9175C0149F0B6CdDE5B68A744C6cCA93a0635f5;
    address constant admin = 0xbbfA751823F04c509346d14E3ec1182405ce2Dc4;
    address constant user_1 = 0x758ae03800AA562399BFe5cffbad98Bfc66776C8;

    IWETH9 constant weth = IWETH9(0x7C068817BcCfE2D2fe3b50f3655e7EEC0a96A88c);
    IStETH constant stETH = IStETH(0x57E540805081E144C0E969009894aadcd4c84a87);
    IWstETH constant wstETH = IWstETH(0xf662c92913B0286860487C868D98DbD750ba8EB0);
    IRETH constant rETH = IRETH(0xF6c184eB69Fa254739daD44287F98F65aB6308fB);
    RocketDepositPoolInterface constant rocketDepositPool =
        RocketDepositPoolInterface(0x42f821436f5456D9a68DF8e16c59537c853d6754);
    // address constant unshETH = 0xD99351D32EC8C067Ea1c8Bbfb41bD27836E871ce;

    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x877D495Edb28B1aFb75B29c4cB626D8B1c26e962);
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xF2E9450a568C01bf7d2A00cab0f729687F4Bfb17);
    ISteamer constant steamer = ISteamer(0x7Da81dF63c3d981E5d7d2caE76e3F2495788706E);
    ISteamerBuffer constant steamerBuffer = ISteamerBuffer(0x1392f0037304AEdc6d955DA1B09A4b944aF33EB4);
    SteamerBuffer constant steamerBufferContract = SteamerBuffer(0x1392f0037304AEdc6d955DA1B09A4b944aF33EB4);
    IWETHGateway constant wethGateway = IWETHGateway(0x63F2962A4aeAe66B489a2Ff3B0af7464BA645442);
    ITokenAdapter constant wstETHAdapter = ITokenAdapter(0xA526A80123AE19F135F0A194a3F7f49a161DCfFd);
    ITokenAdapter constant rETHAdapter = ITokenAdapter(0xb5FfE51493DFB0d9e2e53d7382160481f8fD04eA);
    // ITokenAdapter constant unshETHAdapter = ITokenAdapter(0xc7F20d8Ea6bdEccD28FBA953e7E29d696038e400);

    // IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    // IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // ############################################################################### CONFIGURATIONS ##############

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
        // steamerBuffer.setSteamer(address(weth), address(steamer)); // doesn't need this one registerAsset() is enough
        // steamerBuffer.setFlowRate(address(weth), 5e18);
        // steamerBuffer.registerAsset(address(weth), address(steamer));

        // ############################################################################### VIEW TRANSACTIONS ###########
        // address[] memory underlyingTokens = zeroliquid.getSupportedUnderlyingTokens();
        // console.log("Supported Underlying Token ==> %s", underlyingTokens[0]);
        // address[] memory yieldtokens = zeroliquid.getSupportedYieldTokens();
        // console.log("Supported Yield Token ==> %s, %s, %s", yieldtokens[0], yieldtokens[1], yieldtokens.length);
        // console.log("minimumCollateralization ==> %s", zeroliquid.minimumCollateralization());

        // console.log("Price wstETH ==> %s", wstETHAdapter.price());
        // console.log("Price rETH ==> %s", rETHAdapter.price()); // 1066666666666666666 = total pooled ether / rETH
        // // supply

        // (uint256 sharesWSTETH, uint256 lastAccruedWeightWSTETH) = zeroliquid.positions(deployer, address(wstETH));
        // (uint256 sharesRETH, uint256 lastAccruedWeightRETH) = zeroliquid.positions(deployer, address(rETH));
        // console.log("wstETH ==> Shares: %s, LastAccruedWeight: %s", sharesWSTETH, lastAccruedWeightWSTETH);
        // console.log("rETH ==> Shares: %s, LastAccruedWeight: %s", sharesRETH, lastAccruedWeightRETH);

        // int256 debtWSTETH = zeroliquid.getAccount(deployer, address(wstETH));
        // console.log("Debt wstETH: ");
        // console.logInt(debtWSTETH);
        // int256 debtRETH = zeroliquid.getAccount(deployer, address(rETH));
        // console.log("Debt rETH: ");
        // console.logInt(debtRETH);

        // ############################################################################### SEND TRANSACTIONS ###########
        // MINT WETH
        // weth.deposit{ value: 81_935_483_870_967_748 }();
        // MINT wstETH
        // payable(address(wstETH)).transfer(1e18);
        // MINT rETH
        // transferring ETH in order to generate yield
        // address(rETH).call{ value: 420_430_107_526_881_711 }(new bytes(0));
        // rocketDepositPool.deposit{ value: 10e18 }();

        // DEPOSIT UNDERLYING
        // SafeERC20.safeApprove(address(weth), address(zeroliquid), 1e18);
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(1e18, address(wstETH)));
        // zeroliquid.depositUnderlying(address(wstETH), 1e18, deployer, minimumAmountOut(1e18, address(wstETH)));
        // wethGateway.refreshAllowance(address(zeroliquid));
        // wethGateway.depositUnderlying{ value: 1e18 }(
        //     address(zeroliquid), address(wstETH), 1e18, deployer, minimumAmountOut(1e18, address(wstETH))
        // );

        // DEPOSIT WSTETH
        // SafeERC20.safeApprove(address(wstETH), address(zeroliquid), 1e18);
        // zeroliquid.deposit(address(wstETH), 1e18, deployer);

        // DEPOSIT RETH
        // SafeERC20.safeApprove(address(rETH), address(zeroliquid), 1e18);
        // zeroliquid.deposit(address(rETH), 1e18, deployer);

        // MINT DEBT
        // zeroliquid.mint(address(wstETH), 1e17, deployer);
        // zeroliquid.mint(address(rETH), 1e17, deployer);

        // REPAY DEBT
        // SafeERC20.safeApprove(address(weth), address(zeroliquid), 81_935_483_870_967_748);
        // zeroliquid.repay(address(rETH), address(weth), 81_935_483_870_967_748, deployer);

        // LIQUIDATE
        // zeroliquid.liquidate(address(wstETH), 1e18, minimumAmountOut(1e18, address(wstETH)));

        // WITHDRAW wstETH
        // zeroliquid.withdraw(address(wstETH), 1e18, deployer);
        // zeroliquid.withdraw(address(rETH), 2e18, deployer);

        // HARVEST
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(66_666_666_666_666_666, address(rETH)));
        // zeroliquid.harvest(address(rETH), minimumAmountOut(66_666_666_666_666_665, address(rETH)));

        // ############################################################################### STEAMER BUFFER ##############

        // steamerBuffer.grantRole(keccak256("KEEPER"), admin);
        // bool flag = steamerBuffer.hasRole(keccak256("KEEPER"), admin);
        // console.logBool(flag);

        // console.log(
        //     "TotalCredit wstETH ==> %s, rETH ==> %s",
        //     steamerBuffer.getTotalCredit(address(wstETH)),
        //     steamerBuffer.getTotalCredit(address(rETH))
        // );
        // console.log("TotalUnderlyingBuffered ==> %s", steamerBuffer.getTotalUnderlyingBuffered(address(weth)));
        // console.log("lastFlowrateUpdate ==> %s", steamerBufferContract.lastFlowrateUpdate(address(weth)));

        // console.log(
        //     "getAvailableFlow ==> %s, flowAvailable ==> %s, flowRate ==> %s",
        //     steamerBuffer.getAvailableFlow(address(weth)),
        //     steamerBufferContract.flowAvailable(address(weth)),
        //     steamerBufferContract.flowRate(address(weth))
        // );
        // console.log("Weight ==> %s", steamerBuffer.getWeight(address(weth)));
        // steamerBuffer.exchange(address(weth));

        // ############################################################################### STEAMER #####################

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
        return (amount * 1e18) / yieldTokenPrice(yieldToken);
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
