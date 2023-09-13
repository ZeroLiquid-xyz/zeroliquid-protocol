// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import {
    RETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/rocketpool/RETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IRETH } from "./../../src/interfaces/external/rocketpool/IRETH.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "./../../src/interfaces/external/curve/IStableSwap2Pool.sol";

contract Deployment is Script {
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x0246e28C6B161764492E54CBF852e28A4DA2D672);
    IRETH constant rETH = IRETH(0xae78736Cd615f374D3085123A210448E74Fc6393);
    IWETH9 constant weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    RETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new RETHAdapter(AdapterInitializationParams({
            zeroliquid:      address(zeroliquid),
            token:           address(rETH),
            underlyingToken: address(weth)
        }));

        vm.stopBroadcast();
    }
}
