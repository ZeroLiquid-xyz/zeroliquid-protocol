// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { IZeroLiquidAdminActions } from "./../../src/interfaces/zeroliquid/IZeroLiquidAdminActions.sol";
import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { ISteamerBuffer } from "./../../src/interfaces/steamer/ISteamerBuffer.sol";
import { ZeroLiquid } from "./../../src/ZeroLiquid.sol";

contract Deployment is Script {
    address constant admin = 0x3f5E68DEae10e1Ce34A8Df42F1E2FD2f6B731B91;
    address constant proxyAdmin = 0x250F69e781c728DC5C461a9C1616337BF40A6E0A;
    address constant whitelistETHAddress = 0x28E59622537DC8131199F14a7a2FD17DF09D33d0;
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x947d01482466729756eA55FD0825011A94B039A1);
    ISteamerBuffer constant steamerBuffer = ISteamerBuffer(0x049C3e15E1E465b026ADE3dA5Be68ef6F94aC705);

    TransparentUpgradeableProxy proxyZeroLiquid;
    ZeroLiquid zeroliquidLogic;
    ZeroLiquid zeroliquid;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        zeroliquidLogic = new ZeroLiquid();

        IZeroLiquidAdminActions.InitializationParams memory initializationParams = IZeroLiquidAdminActions
            .InitializationParams({
            admin: admin,
            debtToken: address(zeroliquidtoken),
            steamer: address(steamerBuffer),
            minimumCollateralization: 10 * 1e18,
            protocolFee: 1000,
            protocolFeeReceiver: admin,
            mintingLimitMinimum: 1,
            mintingLimitMaximum: uint256(type(uint160).max),
            mintingLimitBlocks: 300,
            whitelist: whitelistETHAddress
        });

        bytes memory zeroliquidParams = abi.encodeWithSelector(ZeroLiquid.initialize.selector, initializationParams);

        proxyZeroLiquid = new TransparentUpgradeableProxy(address(zeroliquidLogic), proxyAdmin, zeroliquidParams);

        zeroliquid = ZeroLiquid(address(proxyZeroLiquid));

        vm.stopBroadcast();
    }
}
