// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import { Whitelist } from "./../../src/utils/Whitelist.sol";

contract Deployment is Script {
    Whitelist whitelist;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        whitelist = new Whitelist();

        vm.stopBroadcast();
    }
}
