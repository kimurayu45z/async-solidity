// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AsyncFunction} from "../src/AsyncFunction.sol";

contract AsyncFunctionScript is Script {
    AsyncFunction public asyncFunction;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        asyncFunction = new AsyncFunction();

        vm.stopBroadcast();
    }
}
