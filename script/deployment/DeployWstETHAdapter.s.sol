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
    IZeroLiquid constant zeroliquid = IZeroLiquid(0xC818A4A3A82B07871B8Fea72579a9158272Ac052);
    IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IStETH constant stETH = IStETH(0x371F5875B42F4f3AC4195e487CF66Ef9BA0D781F);
    IWstETH constant wstETH = IWstETH(0xBB52CEB2cdbb2f31F7420dD5B8198d25E42750F1);
    IWETH9 constant weth = IWETH9(0xFb1cCC535677AcaED2E0dE6B03736E382216CB5A);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0xBFeEA9179F348cA21D650BABA45fb172749F9E89);

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
