// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { IZeroLiquidToken } from "./../../src/interfaces/IZeroLiquidToken.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { Steamer } from "./../../src/Steamer.sol";
import { SteamerBuffer } from "./../../src/SteamerBuffer.sol";

contract Deployment is Script {
    address constant admin = 0xbbfA751823F04c509346d14E3ec1182405ce2Dc4;
    address constant proxyAdmin = 0xBD35220FDD6dB91d64dca714FEEf9C6614c448a9;
    IZeroLiquidToken constant zeroliquidtoken = IZeroLiquidToken(0x877D495Edb28B1aFb75B29c4cB626D8B1c26e962);
    IWETH9 constant weth = IWETH9(0x7C068817BcCfE2D2fe3b50f3655e7EEC0a96A88c);

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

        bytes memory steamBufParams =
            abi.encodeWithSelector(SteamerBuffer.initialize.selector, admin, address(zeroliquidtoken));

        proxySteamerBuffer = new TransparentUpgradeableProxy(
            address(steamerBufferLogic),
            proxyAdmin,
            steamBufParams
        );

        steamerBuffer = SteamerBuffer(address(proxySteamerBuffer));

        bytes memory steamParams = abi.encodeWithSelector(
            Steamer.initialize.selector, address(zeroliquidtoken), address(weth), address(steamerBuffer)
        );

        proxySteamer = new TransparentUpgradeableProxy(address(steamerLogic), proxyAdmin, steamParams);

        steamer = Steamer(address(proxySteamer));

        vm.stopBroadcast();
    }
}
