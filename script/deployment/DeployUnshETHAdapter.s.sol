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
    address constant unshETH = 0x73F6132Fe65E1f20B91F35E09A25A7B603381Fa9;
    address constant lsdVault = 0x1e5d8427C6D31469c56694C826A4018CdF4f6b56;
    address constant unshEthZap = 0xf72b26F2eE33F5e38f65f392540Fc672E3Aec9e6;
    IWETH9 constant weth = IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0xf21ce491Ff00fd08e29aB308be45D6b5AF69387B);

    UnshETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new UnshETHAdapter(AdapterInitializationParams({
            zeroliquid:       address(zeroliquid),
            lsdVault:         lsdVault,
            unshEthZap:       unshEthZap,
            token:             unshETH,
            underlyingToken: address(weth),
            curvePool:       address(curvePool),
            ethPoolIndex:    0,
            unshEthPoolIndex:  1
        }));

        vm.stopBroadcast();
    }
}
