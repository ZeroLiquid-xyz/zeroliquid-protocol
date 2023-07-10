// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { Steamer } from "./../../src/Steamer.sol";
import { SteamerBuffer } from "./../../src/SteamerBuffer.sol";

contract Deployment is Script {
    address constant admin = 0x3f5E68DEae10e1Ce34A8Df42F1E2FD2f6B731B91;
    address constant proxyAdmin = 0x250F69e781c728DC5C461a9C1616337BF40A6E0A;
    address constant whitelistAddress = 0x28E59622537DC8131199F14a7a2FD17DF09D33d0;
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x947d01482466729756eA55FD0825011A94B039A1);
    IWETH9 constant weth = IWETH9(0x8dF8C7506708BE301340B25fC4d928F7829F68E1);

    Steamer steamer;
    SteamerBuffer steamerBuffer;

    Steamer steamerLogic;
    SteamerBuffer steamerBufferLogic;

    TransparentUpgradeableProxy proxySteamer;
    TransparentUpgradeableProxy proxySteamerBuffer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        steamerBufferLogic = new SteamerBuffer();
        steamerLogic = new Steamer();

        bytes memory transBufParams =
            abi.encodeWithSelector(SteamerBuffer.initialize.selector, admin, address(zeroliquidtoken));

        proxySteamerBuffer = new TransparentUpgradeableProxy(
            address(steamerBufferLogic),
            proxyAdmin,
            transBufParams
        );

        steamerBuffer = SteamerBuffer(address(proxySteamerBuffer));

        bytes memory transParams = abi.encodeWithSelector(
            Steamer.initialize.selector,
            address(zeroliquidtoken),
            address(weth),
            address(steamerBuffer),
            whitelistAddress
        );

        proxySteamer = new TransparentUpgradeableProxy(address(steamerLogic), proxyAdmin, transParams);

        steamer = Steamer(address(proxySteamer));

        vm.stopBroadcast();
    }
}
