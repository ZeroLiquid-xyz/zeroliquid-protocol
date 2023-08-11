// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import {
    WstETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/lido/WstETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IChainlinkOracle } from "./../../src/interfaces/external/chainlink/IChainlinkOracle.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "./../../src/interfaces/external/curve/IStableSwap2Pool.sol";
import { IStETH } from "./../../src/interfaces/external/lido/IStETH.sol";
import { IWstETH } from "./../../src/interfaces/external/lido/IWstETH.sol";

import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";

contract Deployment is Script {
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xF2E9450a568C01bf7d2A00cab0f729687F4Bfb17);
    IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IStETH constant stETH = IStETH(0x57E540805081E144C0E969009894aadcd4c84a87);
    IWstETH constant wstETH = IWstETH(0xf662c92913B0286860487C868D98DbD750ba8EB0);
    IWETH9 constant weth = IWETH9(0x7C068817BcCfE2D2fe3b50f3655e7EEC0a96A88c);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0x1052153abA3e5Bcf5e278b71036e0Ab9BABc3F1b);

    WstETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new WstETHAdapter(AdapterInitializationParams({
            zeroliquid:       address(zeroliquid),
            token:           address(wstETH),
            parentToken:     address(stETH),
            underlyingToken: address(weth),
            curvePool:       address(curvePool),
            oracleStethUsd:  address(oracleStethUsd),
            oracleEthUsd:    address(oracleEthUsd),
            ethPoolIndex:    0,
            stEthPoolIndex:  1,
            referral:        address(0)
        }));

        vm.stopBroadcast();
    }
}
