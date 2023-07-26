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
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0xD077c1b31b1eC141DF3D64cC240C92053998F7ab);
    ISteamerBuffer constant proxySteamerBuffer = ISteamerBuffer(0x36D01326a68C254E416E25058C462dDd20FaA2f2);

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
            protocolFee: 1000,
            protocolFeeReceiver: admin,
            mintingLimitMinimum: 1,
            mintingLimitMaximum: uint256(type(uint160).max),
            mintingLimitBlocks: 300
        });

        bytes memory zeroliquidParams = abi.encodeWithSelector(ZeroLiquid.initialize.selector, initializationParams);

        proxyZeroLiquid = new TransparentUpgradeableProxy(address(zeroliquidLogic), proxyAdmin, zeroliquidParams);

        vm.stopBroadcast();
    }
}
