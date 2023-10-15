// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./UserOpLib.sol";
import "./IEntryPoint.sol";
import "./IAccount.sol";

contract EntryPoint is IEntryPoint {
    using UserOpLib for UserOperation;

    mapping(address => mapping(uint192 => uint64)) sequences;

    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external {
        for(uint256 i; i < ops.length; ++i) {
            // TODO: sender is already deployed or sender is zero and valued initcode.
            // we need factory.
            IAccount(ops[i].sender).validateUserOp(ops[i], ops[i].opHash(address(this)), 0);
        }
    }

    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external
    {}

    function simulateValidation(UserOperation calldata userOp) external {}

    function getNonce(address sender, uint192 key) external view returns (uint256 nonce) {
        uint64 sequence = sequences[sender][key];
        nonce = uint256(bytes32(abi.encodePacked(key, sequence)));
    }
}
