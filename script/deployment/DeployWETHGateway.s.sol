// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import { WETHGateway } from "./../../src/WETHGateway.sol";

contract Deployment is Script {
    WETHGateway wethGateway;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        wethGateway = new WETHGateway(0x984762407b20365A769cd59F1e24576468db5AFB);

        vm.stopBroadcast();
    }
}
