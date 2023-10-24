pragma solidity >=0.8.13;

import { Script } from "forge-std/Script.sol";
import "forge-std/console2.sol";
import "forge-std/console.sol";

import { SafeERC20 } from "./../../src/libraries/SafeERC20.sol";

import { ISwapRouter as IMaverickSwapRouter } from "./../../src/interfaces/external/maverick/ISwapRouter.sol";
import { IPool as IMaverickPool } from "./../../src/interfaces/external/maverick/IPool.sol";

contract MaverickScript is Script {
    address immutable deployer = 0xf9175C0149F0B6CdDE5B68A744C6cCA93a0635f5;
    address immutable maverickRouter = 0x9563Fdb01BFbF3D6c548C2C64E446cb5900ACA88;
    address immutable swETHMaverickPool = 0x33c49FF0916CDe953f99Dbb70703198944Fc62E8;
    address immutable swETH = 0xE685f337FE386cC6094D4ecFa267d2DF63152e74;
    address immutable weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address immutable eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);

        // SafeERC20.safeApprove(swETH, maverickRouter, 10_000_000_000_000);

        IMaverickSwapRouter.ExactInputSingleParams memory params = IMaverickSwapRouter.ExactInputSingleParams({
            tokenIn: swETH,
            tokenOut: weth,
            pool: IMaverickPool(swETHMaverickPool),
            recipient: deployer,
            deadline: block.timestamp,
            amountIn: 10_000_000_000_000,
            amountOutMinimum: 0,
            sqrtPriceLimitD18: 0
        });

        IMaverickSwapRouter(maverickRouter).exactInputSingle(params);

        vm.stopBroadcast();
    }
}
