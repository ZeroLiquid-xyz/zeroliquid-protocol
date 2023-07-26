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
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xC818A4A3A82B07871B8Fea72579a9158272Ac052);
    IRETH constant rETH = IRETH(0xf26c213Ae58eD8f0Aa3A484Fd6d746b4C6287e49);
    IWETH9 constant weth = IWETH9(0xFb1cCC535677AcaED2E0dE6B03736E382216CB5A);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0x7213CF5E0F282fC7129edc2B02602C6e84Be201f);

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
