// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import { ZeroLiquidToken } from "./../../src/ZeroLiquidToken.sol";

contract Deployment is Script {
    ZeroLiquidToken zeroliquidtoken;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        zeroliquidtoken = new ZeroLiquidToken("ZeroLiquid ETH", "zETH", 0xAF8794cDA6Aa82e7E0589B0684a24A47C161f9e2);

        vm.stopBroadcast();
    }
}
