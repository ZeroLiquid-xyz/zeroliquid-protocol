// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import {
    SwETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/swell/SwETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";

import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";

contract Deployment is Script {
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x0246e28C6B161764492E54CBF852e28A4DA2D672);
    IWETH9 constant weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant swETH = 0xf951E335afb289353dc249e82926178EaC7DEd78;
    address constant maverickPool = 0x0CE176E1b11A8f88a4Ba2535De80E81F88592bad;
    address constant maverickRouter = 0xbBF1EE38152E9D8e3470Dc47947eAa65DcA94913;

    SwETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new SwETHAdapter(AdapterInitializationParams({
            zeroliquid: address(zeroliquid),
            token: swETH,
            underlyingToken: address(weth),
            maverickPool: maverickPool,
            maverickRouter: maverickRouter
        }));

        vm.stopBroadcast();
    }
}
