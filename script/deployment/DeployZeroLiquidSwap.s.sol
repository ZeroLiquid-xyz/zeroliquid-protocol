// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import { ZeroLiquidSwap } from "./../../src/ZeroLiquidSwap.sol";

contract Deployment is Script {
    ZeroLiquidSwap swap;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        swap =
        new ZeroLiquidSwap(0x144285De31008b2a8824574655a66DC6F845343e, 0x7A6f697d65B216Fad49322ec40eEeeDD02037057, 0x1900DDbFcc3174A8C1cDd485F5A99f12B93048E9);

        vm.stopBroadcast();
    }
}
