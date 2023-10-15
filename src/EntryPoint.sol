// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./IEntryPoint.sol";

contract EntryPoint is IEntryPoint {

    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external {}

    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external {}

    function simulateValidation(UserOperation calldata userOp) external {}
}
