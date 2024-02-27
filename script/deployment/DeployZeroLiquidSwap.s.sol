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
        new ZeroLiquidSwap(0x0246e28C6B161764492E54CBF852e28A4DA2D672, 0x776280F68aD33c4d49e6846507B7dBaf7811c89F, 0x1111111254EEB25477B68fb85Ed929f73A960582);

        vm.stopBroadcast();
    }
}
