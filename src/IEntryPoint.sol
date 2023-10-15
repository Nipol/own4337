// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./IAggregator.sol";

interface IEntryPoint {
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        IAggregator aggregator;
        bytes signature;
    }

    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        bool sigFailed;
        uint48 validAfter;
        uint48 validUntil;
        bytes paymasterContext;
    }

    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    struct AggregatorStakeInfo {
        address actualAggregator;
        StakeInfo stakeInfo;
    }

    error ValidationResult(ReturnInfo returnInfo, StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

    error ValidationResultWithAggregation(
        ReturnInfo returnInfo,
        StakeInfo senderInfo,
        StakeInfo factoryInfo,
        StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo
    );

    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary)
        external;

    function simulateValidation(UserOperation calldata userOp) external;
}
