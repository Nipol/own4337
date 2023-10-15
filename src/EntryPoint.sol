// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./IEntryPoint.sol";

contract EntryPoint is IEntryPoint {
    mapping(address => mapping(uint192 => uint64)) sequences;

    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external {}

    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external
    {}

    function simulateValidation(UserOperation calldata userOp) external {}

    function getNonce(address sender, uint192 key) external view returns (uint256 nonce) {
        uint64 sequence = sequences[sender][key];
        nonce = uint256(abi.encodePacked(key, sequence));
    }
}
