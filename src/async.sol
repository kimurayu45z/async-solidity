// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/math/Math.sol";

struct Promise {
    address msgSender;
    uint256 id;
    address txOrigin;
    uint256 value;
    address callbackContract;
    string callbackName;
}

contract AsyncFunction {
    mapping(address => uint256) public sequence;
    mapping(address => mapping(uint256 => Promise)) public promises;

    event Resolved(address, uint256, bytes);

    modifier promise_exists(uint256 promise_id) {
        require(
            promises[msg.sender][promise_id].msgSender == address(0),
            "Promise corresponding to the sequence does not exist."
        );
        _;
    }

    function new_promise() external payable returns (Promise memory) {
        uint256 seq = sequence[msg.sender];
        sequence[msg.sender] = seq + 1;

        Promise memory value = Promise(
            msg.sender,
            seq,
            tx.origin,
            msg.value,
            address(0),
            ""
        );
        promises[msg.sender][seq] = value;

        return value;
    }

    function promise_then(
        uint256 promiseId,
        address callbackContract,
        string calldata callbackName
    ) external promise_exists(promiseId) {
        promises[msg.sender][promiseId].callbackContract = callbackContract;
        promises[msg.sender][promiseId].callbackName = callbackName;
    }

    function resolve(
        uint256 promiseId,
        bytes calldata data
    ) external payable promise_exists(promiseId) {
        uint256 start = gasleft();

        uint256 value = promises[msg.sender][promiseId].value;
        address callback_contract = promises[msg.sender][promiseId]
            .callbackContract;
        string memory callback_name = promises[msg.sender][promiseId]
            .callbackName;

        delete promises[msg.sender][promiseId];
        emit Resolved(callback_contract, promiseId, data);

        if (
            callback_contract != address(0) && bytes(callback_name).length > 0
        ) {
            (bool success, ) = callback_contract.call{value: msg.value}(
                abi.encodeWithSignature(
                    string.concat(callback_name, "(address,bytes)"),
                    promises[msg.sender][promiseId].txOrigin,
                    data
                )
            );
            require(success);
        }

        uint256 end = gasleft();
        uint256 used = start - end;
        uint256 refund = used * tx.gasprice + msg.value;
    }
}
