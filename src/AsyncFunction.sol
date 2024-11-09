// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/math/Math.sol";

struct Promise {
    uint256 id;
    address txOrigin;
    uint256 value;
    address callbackContract;
    string callbackName;
}

contract AsyncFunction {
    address public owner;
    uint256 public sequence;
    mapping(uint256 => Promise) public promises;

    constructor() {
        owner = msg.sender;
    }

    event Resolved(address, uint256, bytes);

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier promise_exists(uint256 promise_id) {
        require(promises[promise_id].txOrigin != address(0), "Promise corresponding to the sequence does not exist.");
        _;
    }

    function new_promise() external payable isOwner returns (Promise memory) {
        Promise memory value = Promise(sequence, tx.origin, msg.value, address(0), "");
        promises[sequence] = value;
        sequence = sequence + 1;

        return value;
    }

    function promise_then(uint256 promiseId, address callbackContract, string calldata callbackName)
        external
        isOwner
        promise_exists(promiseId)
    {
        promises[promiseId].callbackContract = callbackContract;
        promises[promiseId].callbackName = callbackName;
    }

    function resolve(uint256 promiseId, bytes calldata data) external payable isOwner promise_exists(promiseId) {
        uint256 start = gasleft();

        address promiseTxOrigin = promises[promiseId].txOrigin;
        uint256 promiseValue = promises[promiseId].value;
        address callbackContract = promises[promiseId].callbackContract;
        string memory callbackName = promises[promiseId].callbackName;

        delete promises[promiseId];
        emit Resolved(callbackContract, promiseId, data);

        if (callbackContract != address(0) && bytes(callbackName).length > 0) {
            (bool success,) = callbackContract.call{value: msg.value}(
                abi.encodeWithSignature(string.concat(callbackName, "(address,bytes)"), promiseTxOrigin, data)
            );
            require(success);
        }

        uint256 end = gasleft();
        uint256 used = start - end;
        uint256 refund = Math.min(used * tx.gasprice + msg.value, promiseValue);

        (bool success_,) = tx.origin.call{value: refund}("");
        require(success_);

        if (promiseValue - refund > 0) {
            (bool success__,) = promiseTxOrigin.call{value: promiseValue - refund}("");
            require(success__);
        }
    }
}
