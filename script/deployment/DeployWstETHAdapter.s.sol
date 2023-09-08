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
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x0246e28C6B161764492E54CBF852e28A4DA2D672);
    IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
    IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IStETH constant stETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IWstETH constant wstETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IWETH9 constant weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

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
