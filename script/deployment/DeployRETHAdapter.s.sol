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
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x19E0503a040CF7283D46ed091Caf35eBEeC84270);
    IRETH constant rETH = IRETH(0x3cD99D149C2A7677D920cEDdeA865129e276D5e4);
    IWETH9 constant weth = IWETH9(0x984762407b20365A769cd59F1e24576468db5AFB);

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
