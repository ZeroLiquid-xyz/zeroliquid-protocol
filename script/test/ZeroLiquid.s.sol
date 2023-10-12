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
import { ZeroLiquidToken } from "src/ZeroLiquidToken.sol";
import { SteamerBuffer } from "src/SteamerBuffer.sol";
import { IWETHGateway } from "src/interfaces/IWETHGateway.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ZeroLiquidScript is Script {
    uint256 constant BPS = 10_000;
    address constant deployer = 0xf9175C0149F0B6CdDE5B68A744C6cCA93a0635f5;
    address constant admin = 0xbbfA751823F04c509346d14E3ec1182405ce2Dc4;
    address constant user_m = 0x92cd1E7EC07B407027e8F667eB0C7354219f2433;

    IWETH9 constant weth = IWETH9(0x984762407b20365A769cd59F1e24576468db5AFB);
    IStETH constant stETH = IStETH(0x75AeF7E517dec2B37322Db16d490990844f7c3F9);
    IWstETH constant wstETH = IWstETH(0x3A4bD8Bf2343E6F636d35b25B9CebBC1DB6BbEC5);
    IRETH constant rETH = IRETH(0x3cD99D149C2A7677D920cEDdeA865129e276D5e4);
    RocketDepositPoolInterface constant rocketDepositPool =
        RocketDepositPoolInterface(0x7C61aa35b5578248267d2fAEa9eD02F03A075A74);
    address constant unshETH = 0x73F6132Fe65E1f20B91F35E09A25A7B603381Fa9;

    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x888ED3D6Af5418098C16B8445caeea2081399636);
    ZeroLiquidToken constant zeroliquidtokenContract = ZeroLiquidToken(0x888ED3D6Af5418098C16B8445caeea2081399636);
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x144285De31008b2a8824574655a66DC6F845343e);
    ISteamer constant steamer = ISteamer(0x4875a0c9ED805FdE1751aC328b3ad6CB5b170087);
    ISteamerBuffer constant steamerBuffer = ISteamerBuffer(0x74826F19Dd0063823D47d9404Fb5Dfc3473Ccd78);
    SteamerBuffer constant steamerBufferContract = SteamerBuffer(0x74826F19Dd0063823D47d9404Fb5Dfc3473Ccd78);
    IWETHGateway constant wethGateway = IWETHGateway(0x92e322fF92EDe3ad6DBc85Ef53e5E13beE5f2331);
    ITokenAdapter constant wstETHAdapter = ITokenAdapter(0x472Df508a07dDBe64AA84fE8E9eAf7B7BDeA36e9);
    ITokenAdapter constant rETHAdapter = ITokenAdapter(0x0B60b240ccc513201D74c605c559627151065dE1);
    ITokenAdapter constant unshETHAdapter = ITokenAdapter(0x180F06F624f39960576C06d5e3c5B042A43e6466);
    // ITokenAdapter constant unshETHAdapter = ITokenAdapter(0xc7F20d8Ea6bdEccD28FBA953e7E29d696038e400);

    // IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    // IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ADMIN");
        vm.startBroadcast(deployerPrivateKey);

        // ############################################################################### CONFIGURATIONS ##############

        // SEND USING ADMIN
        // zeroliquid.addUnderlyingToken(
        //     address(weth),
        //     IZeroLiquidAdminActions.UnderlyingTokenConfig({
        //         repayLimitMinimum: 100e18,
        //         repayLimitMaximum: 600e18,
        //         repayLimitBlocks: 300,
        //         liquidationLimitMinimum: 100e18,
        //         liquidationLimitMaximum: 600e18,
        //         liquidationLimitBlocks: 300
        //     })
        // );
        // zeroliquid.setUnderlyingTokenEnabled(address(weth), true);

        // zeroliquid.addYieldToken(
        //     address(wstETH),
        //     IZeroLiquidAdminActions.YieldTokenConfig({
        //         adapter: address(wstETHAdapter),
        //         maximumLoss: 100,
        //         maximumExpectedValue: 1000e18,
        //         creditUnlockBlocks: 7200
        //     })
        // );
        // zeroliquid.setYieldTokenEnabled(address(wstETH), true);
        // zeroliquid.setTokenAdapter(address(wstETH), address(wstETHAdapter));

        // zeroliquid.addYieldToken(
        //     address(rETH),
        //     IZeroLiquidAdminActions.YieldTokenConfig({
        //         adapter: address(rETHAdapter),
        //         maximumLoss: 100,
        //         maximumExpectedValue: 1000e18,
        //         creditUnlockBlocks: 7200
        //     })
        // );
        // zeroliquid.setYieldTokenEnabled(address(rETH), true);
        // zeroliquid.setTokenAdapter(address(rETH), address(rETHAdapter));

        zeroliquid.addYieldToken(
            address(unshETH),
            IZeroLiquidAdminActions.YieldTokenConfig({
                adapter: address(unshETHAdapter),
                maximumLoss: 100,
                maximumExpectedValue: 100e18,
                creditUnlockBlocks: 7200
            })
        );
        zeroliquid.setYieldTokenEnabled(address(unshETH), true);
        zeroliquid.setTokenAdapter(address(unshETH), address(unshETHAdapter));

        // SEND USING OWNER OF ZEROLIQUID TOKEN
        // zeroliquidtoken.setWhitelist(address(zeroliquid), true);

        // SEND USING ADMIN
        // zeroliquid.setKeeper(admin, true);
        // steamerBuffer.setZeroLiquid(address(zeroliquid));
        // steamerBuffer.setSteamer(address(weth), address(steamer)); // doesn't need this one registerAsset() is
        // enough
        // steamerBuffer.registerAsset(address(weth), address(steamer));
        // steamerBuffer.setFlowRate(address(weth), 20_000_000_000_000_000);
        // wethGateway.refreshAllowance(address(zeroliquid));

        // ################################################################################### VIEW CONFIGS ###########

        // console.log(
        //     "zETH ==> ADMIN: %s, SENTINEL: %s",
        //     zeroliquidtokenContract.hasRole(keccak256("ADMIN"), deployer),
        //     zeroliquidtokenContract.hasRole(keccak256("SENTINEL"), deployer)
        // );

        // zeroliquidtokenContract.renounceRole(keccak256("ADMIN"), deployer);
        // zeroliquidtokenContract.renounceRole(keccak256("SENTINEL"), deployer);

        // address[] memory underlyingTokens = zeroliquid.getSupportedUnderlyingTokens();
        // console.log("Supported Underlying Token ==> %s", underlyingTokens[0]);
        // address[] memory yieldtokens = zeroliquid.getSupportedYieldTokens();
        // console.log("Supported Yield Token ==> %s, %s, %s", yieldtokens[0], yieldtokens[1], yieldtokens.length);
        // console.log("minimumCollateralization ==> %s", zeroliquid.minimumCollateralization());

        // ################################################################################## VIEW POSITIONS ###########

        // console.log("Price wstETH ==> %s", wstETHAdapter.price());
        // console.log("Price rETH ==> %s", rETHAdapter.price()); // 1066666666666666666 = total pooled ether / rETH
        // // supply

        // console.log(
        //     "Balance wstETH ==> %s, rETH ==> %s, zETH ==> %s",
        //     IERC20(address(wstETH)).balanceOf(deployer),
        //     IERC20(address(rETH)).balanceOf(deployer),
        //     IERC20(address(zeroliquidtoken)).balanceOf(deployer)
        // );
        // (uint256 sharesWSTETH, uint256 lastAccruedWeightWSTETH) = zeroliquid.positions(deployer, address(wstETH));
        // (uint256 sharesRETH, uint256 lastAccruedWeightRETH) = zeroliquid.positions(deployer, address(rETH));
        // console.log("wstETH ==> Shares: %s, LastAccruedWeight: %s", sharesWSTETH, lastAccruedWeightWSTETH);
        // console.log("rETH ==> Shares: %s, LastAccruedWeight: %s", sharesRETH, lastAccruedWeightRETH);

        // (int256 debt,) = zeroliquid.accounts(deployer);
        // console.log("Debt: ");
        // console.logInt(debt);

        // ############################################################################### SEND TRANSACTIONS ###########
        // MINT WETH
        // weth.deposit{ value: 81_935_483_870_967_748 }();
        // MINT wstETH
        // address(wstETH).call{ value: 1e18 }(new bytes(0));
        // MINT rETH
        // transferring ETH in order to generate yield
        // address(rETH).call{ value: 420_430_107_526_881_711 }(new bytes(0));
        // rocketDepositPool.deposit{ value: 1e18 }();
        // IERC20(address(wstETH)).transfer(deployer, 1);

        // DEPOSIT UNDERLYING
        // SafeERC20.safeApprove(address(weth), address(zeroliquid), 1e18);
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(1e18, address(wstETH)));
        // zeroliquid.depositUnderlying(address(wstETH), 1e18, deployer, minimumAmountOut(1e18, address(wstETH)));
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
        // zeroliquid.mint(1e17, deployer);

        // BURN DEBT
        // SafeERC20.safeApprove(address(zeroliquidtoken), address(zeroliquid), 2e17);
        // zeroliquid.burn(2e17, deployer);

        // REPAY DEBT
        // SafeERC20.safeApprove(address(weth), address(zeroliquid), 81_935_483_870_967_748);
        // zeroliquid.repay(address(rETH), address(weth), 81_935_483_870_967_748, deployer);

        // LIQUIDATE
        // zeroliquid.liquidate(address(wstETH), 1e18, minimumAmountOut(1e17, address(wstETH)));

        // WITHDRAW wstETH
        // zeroliquid.withdraw(address(wstETH), 1e18, deployer);
        // zeroliquid.withdraw(address(rETH), 2e18, deployer);

        // HARVEST
        // console.log("minimumAmountOut ==> %s", minimumAmountOut(66_666_666_666_666_666, address(rETH)));
        // zeroliquid.harvest(address(rETH), minimumAmountOut(66_666_666_666_666_665, address(rETH)));

        // ############################################################################### STEAMER BUFFER ##############

        // steamerBufferContract.grantRole(keccak256("KEEPER"), admin);
        // bool flag = steamerBufferContract.hasRole(keccak256("KEEPER"), admin);
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

        // console.log(
        //     "UnexchangedBalance => %s, ExchangedBalance => %s, ClaimableBalance => %s",
        //     steamer.getUnexchangedBalance(deployer),
        //     steamer.getExchangedBalance(deployer),
        //     steamer.getClaimableBalance(deployer)
        // );
        // console.log(
        //     "Deposited => %s, Withdrawable => %s, Claimable => %s",
        //     (steamer.getExchangedBalance(deployer) + steamer.getUnexchangedBalance(deployer)),
        //     steamer.getUnexchangedBalance(deployer),
        //     steamer.getClaimableBalance(deployer)
        // );

        // SafeERC20.safeApprove(address(zeroliquidtoken), address(steamer), 2e16);
        // steamer.deposit(2e16, deployer);
        // steamer.withdraw(2e16, deployer);
        // steamer.claim(1e18, deployer);

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
