// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { IZeroLiquidAdminActions } from "./../../src/interfaces/zeroliquid/IZeroLiquidAdminActions.sol";
import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { ISteamerBuffer } from "./../../src/interfaces/steamer/ISteamerBuffer.sol";
import { ZeroLiquid } from "./../../src/ZeroLiquid.sol";

contract Deployment is Script {
    address constant admin = 0xAF8794cDA6Aa82e7E0589B0684a24A47C161f9e2;
    address constant proxyAdmin = 0x9FA1B904ba1E29ed45E183EFE6a47aCDC2d15eFA;
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x776280F68aD33c4d49e6846507B7dBaf7811c89F);
    ISteamerBuffer constant proxySteamerBuffer = ISteamerBuffer(0xc429B3aABa6daC296BD5b6d42513683f1f22C5b1);
    address constant zeroliquidLogicAddress = 0x1b6a205358e9378Bf9d6cb75F4D3cCcab38cA796;

    TransparentUpgradeableProxy proxyZeroLiquid;
    ZeroLiquid zeroliquidLogic;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        zeroliquidLogic = new ZeroLiquid();

        IZeroLiquidAdminActions.InitializationParams memory initializationParams = IZeroLiquidAdminActions
            .InitializationParams({
            admin: admin,
            debtToken: address(zeroliquidtoken),
            steamer: address(proxySteamerBuffer),
            minimumCollateralization: 10 * 1e18,
            protocolFee: 0,
            protocolFeeReceiver: admin,
            mintingLimitMinimum: 100e18,
            mintingLimitMaximum: 600e18,
            mintingLimitBlocks: 300
        });

        bytes memory zeroliquidParams = abi.encodeWithSelector(ZeroLiquid.initialize.selector, initializationParams);

        proxyZeroLiquid = new TransparentUpgradeableProxy(zeroliquidLogicAddress, proxyAdmin, zeroliquidParams);

        vm.stopBroadcast();
    }
}
