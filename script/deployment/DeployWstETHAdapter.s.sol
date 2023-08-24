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
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x19E0503a040CF7283D46ed091Caf35eBEeC84270);
    IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IStETH constant stETH = IStETH(0x75AeF7E517dec2B37322Db16d490990844f7c3F9);
    IWstETH constant wstETH = IWstETH(0x3A4bD8Bf2343E6F636d35b25B9CebBC1DB6BbEC5);
    IWETH9 constant weth = IWETH9(0x984762407b20365A769cd59F1e24576468db5AFB);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0x578BB2E3E39e7260b3f6a81a8C6460Da5ad04d1C);

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
