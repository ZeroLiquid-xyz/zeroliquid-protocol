// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import {
    UnshETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/unsheth/UnshETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "./../../src/interfaces/external/curve/IStableSwap2Pool.sol";

contract Deployment is Script {
    uint256 constant BPS = 10_000;
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xAe482AaBB145c7492fDCaE7FAebdf3519B91a55a);
    address constant unshETH = 0xD99351D32EC8C067Ea1c8Bbfb41bD27836E871ce;
    address constant lsdVault = 0x09b4816583e7d342fD9F69a588D4d3ACa2D7D3Cb;
    address constant unshEthZap = 0xBAD18Fa1531f7f82F457bD2028827b4De3c63A74;
    IWETH9 constant weth = IWETH9(0x8dF8C7506708BE301340B25fC4d928F7829F68E1);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0x8566168D2C970EA21c46b9BB3dA8BCDAF7f9b0c3);

    UnshETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new UnshETHAdapter(AdapterInitializationParams({
            zeroliquid:       address(zeroliquid),
            lsdVault:         lsdVault,
            unshEthZap:       unshEthZap,
            token:             unshETH,
            underlyingToken: address(weth),
            curvePool:       address(curvePool),
            ethPoolIndex:    0,
            unshEthPoolIndex:  1,
            referral:        address(0)
        }));

        vm.stopBroadcast();
    }
}
