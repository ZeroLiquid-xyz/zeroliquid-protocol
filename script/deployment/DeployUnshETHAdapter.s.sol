// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import {
    UnshETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/unsheth/UnshETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "./../../src/interfaces/external/curve/IStableSwap2Pool.sol";

contract Deployment is Script {
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x0246e28C6B161764492E54CBF852e28A4DA2D672);
    address constant unshETH = 0x0Ae38f7E10A43B5b2fB064B42a2f4514cbA909ef;
    IWETH9 constant weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant lsdVault = 0x51A80238B5738725128d3a3e06Ab41c1d4C05C74;
    address constant unshEthZap = 0xc258fF338322b6852C281936D4EdEff8AdfF23eE;

    UnshETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new UnshETHAdapter(AdapterInitializationParams({
            zeroliquid: address(zeroliquid),
            token: unshETH,
            underlyingToken: address(weth),
            lsdVault: lsdVault,
            unshEthZap: unshEthZap,

            // stETH
            stETHCurvePool: 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022,
            ethIndexStETHCurvePool: 0,
            stETHIndexCurvePool: 1,
            // frxETH
            frxETHCurvePool: 0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577,
            ethIndexFrxETHCurvePool: 0,
            frxETHIndexCurvePool: 1,
            // ankrETH
            ankrETHCurvePool: 0xA96A65c051bF88B4095Ee1f2451C2A9d43F53Ae2,
            ethIndexAnkrETHCurvePool: 0,
            ankrETHIndexCurvePool: 1,
            // swETH
            swETHMaverickPool: 0x0CE176E1b11A8f88a4Ba2535De80E81F88592bad,
            maverickRouter: 0xbBF1EE38152E9D8e3470Dc47947eAa65DcA94913
        }));

        vm.stopBroadcast();
    }
}
