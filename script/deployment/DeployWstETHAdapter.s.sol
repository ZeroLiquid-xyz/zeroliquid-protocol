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
import { IWhitelist } from "./../../src/interfaces/IWhitelist.sol";

import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";

contract Deployment is Script {
    uint256 constant BPS = 10_000;
    // address constant admin = 0xbbfA751823F04c509346d14E3ec1182405ce2Dc4;
    address constant whitelistETHAddress = 0x28E59622537DC8131199F14a7a2FD17DF09D33d0;

    IZeroLiquid constant zeroliquid = IZeroLiquid(0xAe482AaBB145c7492fDCaE7FAebdf3519B91a55a);
    IChainlinkOracle constant oracleStethUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IChainlinkOracle constant oracleEthUsd = IChainlinkOracle(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    IStETH constant stETH = IStETH(0xCa757555fA05Ed1F228dE4938A9921C2e3eAAfF9);
    IWstETH constant wstETH = IWstETH(0xf9D689e2aBaC0f531360d16D129fA11B331Dc2e0);
    IWETH9 constant weth = IWETH9(0x8dF8C7506708BE301340B25fC4d928F7829F68E1);
    IStableSwap2Pool constant curvePool = IStableSwap2Pool(0x8566168D2C970EA21c46b9BB3dA8BCDAF7f9b0c3);

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

        // zeroliquid.setTokenAdapter(address(wstETH), address(adapter));
        // IWhitelist(whitelistETHAddress).add(address(this));
        // zeroliquid.setMaximumExpectedValue(address(wstETH), 1_000_000_000e18);

        vm.stopBroadcast();
    }
}
