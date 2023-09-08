// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { Steamer } from "./../../src/Steamer.sol";
import { SteamerBuffer } from "./../../src/SteamerBuffer.sol";

contract Deployment is Script {
    address constant admin = 0xAF8794cDA6Aa82e7E0589B0684a24A47C161f9e2;
    address constant proxyAdmin = 0x9FA1B904ba1E29ed45E183EFE6a47aCDC2d15eFA;
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x776280F68aD33c4d49e6846507B7dBaf7811c89F);
    IWETH9 constant weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address constant steamerBufferLogicAddress = 0x2AF772E90398B6Eca5bfb4c36d20bEAb71979938;
    address constant steamerLogicAddress = 0x81373f4E8D0BD48bbE8842E9eE16dB7B60c20613;
    address constant steamerBufferProxyAddress = 0xc429B3aABa6daC296BD5b6d42513683f1f22C5b1;

    Steamer steamer;
    SteamerBuffer steamerBuffer;

    Steamer steamerLogic;
    SteamerBuffer steamerBufferLogic;

    TransparentUpgradeableProxy proxySteamer;
    TransparentUpgradeableProxy proxySteamerBuffer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // steamerBufferLogic = new SteamerBuffer();
        // steamerLogic = new Steamer();

        // bytes memory steamBufParams =
        //     abi.encodeWithSelector(SteamerBuffer.initialize.selector, admin, address(zeroliquidtoken));

        // proxySteamerBuffer = new TransparentUpgradeableProxy(
        //     steamerBufferLogicAddress,
        //     proxyAdmin,
        //     steamBufParams
        // );

        // steamerBuffer = SteamerBuffer(steamerBufferProxyAddress);

        // bytes memory steamParams = abi.encodeWithSelector(
        //     Steamer.initialize.selector, address(zeroliquidtoken), address(weth), steamerBufferProxyAddress
        // );

        // proxySteamer = new TransparentUpgradeableProxy(address(steamerLogicAddress), proxyAdmin, steamParams);

        // steamer = Steamer(address(proxySteamer));

        vm.stopBroadcast();
    }
}
