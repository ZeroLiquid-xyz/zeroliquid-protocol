// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import { ZeroLiquidSwap } from "./../../src/ZeroLiquidSwap.sol";

contract Deployment is Script {
    ZeroLiquidSwap swap;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // zeroliquid, debtToken, swapRouter, stableSwap, wethPoolIndex, zethPoolIndex
        swap =
        new ZeroLiquidSwap(0x144285De31008b2a8824574655a66DC6F845343e, 0x7A6f697d65B216Fad49322ec40eEeeDD02037057, 0xE6A7D7024e3a1EBec0f7EFa74F7175526e352bBE, 0xaf15De327d7E548d8f58574c67D2bEaC18E4f9e7, 1, 0);

        vm.stopBroadcast();
    }
}
