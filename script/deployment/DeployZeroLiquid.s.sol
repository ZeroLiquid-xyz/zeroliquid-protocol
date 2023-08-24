// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { IZeroLiquidAdminActions } from "./../../src/interfaces/zeroliquid/IZeroLiquidAdminActions.sol";
import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { ISteamerBuffer } from "./../../src/interfaces/steamer/ISteamerBuffer.sol";
import { ZeroLiquid } from "./../../src/ZeroLiquid.sol";

contract Deployment is Script {
    address constant admin = 0xbbfA751823F04c509346d14E3ec1182405ce2Dc4;
    address constant proxyAdmin = 0xBD35220FDD6dB91d64dca714FEEf9C6614c448a9;
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x888ED3D6Af5418098C16B8445caeea2081399636);
    ISteamerBuffer constant proxySteamerBuffer = ISteamerBuffer(0x74826F19Dd0063823D47d9404Fb5Dfc3473Ccd78);

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
            mintingLimitMinimum: 100_000_000_000_000_000_000,
            mintingLimitMaximum: 600_000_000_000_000_000_000,
            mintingLimitBlocks: 300
        });

        bytes memory zeroliquidParams = abi.encodeWithSelector(ZeroLiquid.initialize.selector, initializationParams);

        proxyZeroLiquid = new TransparentUpgradeableProxy(address(zeroliquidLogic), proxyAdmin, zeroliquidParams);

        vm.stopBroadcast();
    }
}
