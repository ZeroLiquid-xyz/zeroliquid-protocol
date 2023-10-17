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
    uint256 constant BPS = 10_000;
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x144285De31008b2a8824574655a66DC6F845343e);
    address constant unshETH = 0x74173e088D9F540F7f55CE9c61f9186cF9D62D81;
    IWETH9 constant weth = IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    address constant lsdVault = 0xA5770E0E4cB2786f64F6d4CD889A008186718f79;
    address constant unshEthZap = 0x1C36EfE1c6Af4438046DaA342D8628D6d1549A08;

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
            stETHCurvePool: 0xa6957A68b7931199208dCEBc7f08BEEDa07dd523,
            ethIndexStETHCurvePool: 0,
            stETHIndexCurvePool: 1,
            // frxETH
            frxETHCurvePool: 0x94CCbD0FA8B5507097cb13e8C5EC87F0050782a8,
            ethIndexFrxETHCurvePool: 0,
            frxETHIndexCurvePool: 1,
            // cbETH
            cbETHCurvePool: 0x7c52490470ca36bF565D8C42d9f109c53960b541,
            ethIndexCbETHCurvePool: 0,
            cbETHIndexCurvePool: 1,
            // ankrETH
            ankrETHCurvePool: 0x93afF571C259dF43461F47370286e17B6e30E97E,
            ethIndexAnkrETHCurvePool: 0,
            ankrETHIndexCurvePool: 1,
            // swETH
            swETHMaverickPool: 0x33c49FF0916CDe953f99Dbb70703198944Fc62E8,
            maverickRouter: 0x9563Fdb01BFbF3D6c548C2C64E446cb5900ACA88
        }));

        vm.stopBroadcast();
    }
}
