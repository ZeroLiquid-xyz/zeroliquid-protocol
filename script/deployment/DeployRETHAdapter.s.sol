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
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xF2E9450a568C01bf7d2A00cab0f729687F4Bfb17);
    IRETH constant rETH = IRETH(0xF6c184eB69Fa254739daD44287F98F65aB6308fB);
    IWETH9 constant weth = IWETH9(0x7C068817BcCfE2D2fe3b50f3655e7EEC0a96A88c);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0xB466036BBDe1afeCA12e64644fe53D565D9C24c9);

    RETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new RETHAdapter(AdapterInitializationParams({
            zeroliquid:      address(zeroliquid),
            token:           address(rETH),
            underlyingToken: address(weth),
            curvePool:       address(curvePool),
            ethPoolIndex:    0,
            rEthPoolIndex:   1
        }));

        vm.stopBroadcast();
    }
}
