// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";

import {
    StakedFraxETHAdapter,
    InitializationParams as AdapterInitializationParams
} from "./../../src/adapters/frax/StakedFraxETHAdapter.sol";

import { IZeroLiquid } from "./../../src/interfaces/IZeroLiquid.sol";
import { IWETH9 } from "./../../src/interfaces/external/IWETH9.sol";
import { IStableSwap2Pool } from "./../../src/interfaces/external/curve/IStableSwap2Pool.sol";
import { IFraxMinter } from "./../../src/interfaces/external/frax/IFraxMinter.sol";
import { IFraxEth } from "./../../src/interfaces/external/frax/IFraxEth.sol";
import { IStakedFraxEth } from "./../../src/interfaces/external/frax/IStakedFraxEth.sol";

import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";

contract Deployment is Script {
    IZeroLiquid constant zeroliquid = IZeroLiquid(0x0246e28C6B161764492E54CBF852e28A4DA2D672);
    IStakedFraxEth constant sfrxETH = IStakedFraxEth(0xac3E018457B222d93114458476f3E3416Abbe38F);
    IFraxMinter constant minter = IFraxMinter(0xbAFA44EFE7901E04E39Dad13167D089C559c1138);
    IFraxEth constant fraxETH = IFraxEth(0x5E8422345238F34275888049021821E8E08CAa1f);
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577);

    StakedFraxETHAdapter adapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        adapter = new StakedFraxETHAdapter(AdapterInitializationParams({
            zeroliquid:      address(zeroliquid),
            token:           address(sfrxETH),
            minter:          address(minter),
            parentToken:     address(fraxETH),
            underlyingToken: address(weth),
            curvePool:       address(curvePool),
            curvePoolEthIndex:    0,
            curvePoolFrxEthIndex:  1
        }));

        vm.stopBroadcast();
    }
}
