// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AsyncFunction, Promise} from "../src/async.sol";

contract AccountA {}

contract AsyncFunctionTest is Test {
    AsyncFunction public asyncFunction;
    AccountA public accountA;
    Promise promise_;

    function setUp() public payable {
        asyncFunction = new AsyncFunction();

        accountA = new AccountA();
        (bool success, ) = address(accountA).call{value: 1000}("");
        require(success);
    }

    function create() public payable {
        promise_ = asyncFunction.new_promise{value: msg.value}();
    }

    function resolve() public payable {
        asyncFunction.resolve(promise_.id, bytes(""));
    }

    function callback(bytes calldata data) public payable {}
}
