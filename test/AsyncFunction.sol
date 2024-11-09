// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AsyncFunction, Promise} from "../src/AsyncFunction.sol";

contract AsyncFunctionTest is Test {
    AsyncFunction public asyncFunction;
    Promise promise_;

    function setUp() public {
        asyncFunction = new AsyncFunction();
    }

    function callback(address txOrigin, bytes calldata data) public payable {
        console.log("txOrigin", txOrigin);
        console.log(string(data));
        require(msg.value >= 1000, "callback requires 1000+");

        (bool success,) = address(1).call{value: 1000}("");
        require(success);
    }

    function testPromise() public {
        console.log("txOrigin", tx.origin);

        console.log(
            tx.origin.balance + 2000, address(this).balance - 2000, address(asyncFunction).balance, address(1).balance
        );
        console.log(tx.origin.balance, address(this).balance, address(asyncFunction).balance, address(1).balance);
        promise_ = asyncFunction.new_promise{value: 2000}();
        asyncFunction.promise_then(promise_.id, address(this), "callback");

        console.log(tx.origin.balance, address(this).balance, address(asyncFunction).balance, address(1).balance);
        asyncFunction.resolve{value: 1000}(promise_.id, bytes("1000+ paid"));

        console.log(tx.origin.balance, address(this).balance, address(asyncFunction).balance, address(1).balance);
    }
}
