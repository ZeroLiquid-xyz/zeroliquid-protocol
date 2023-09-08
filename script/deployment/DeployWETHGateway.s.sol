// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import { WETHGateway } from "./../../src/WETHGateway.sol";

contract Deployment is Script {
    WETHGateway wethGateway;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        wethGateway = new WETHGateway(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        vm.stopBroadcast();
    }
}
