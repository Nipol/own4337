// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";

library UserOpLib {
    // 1번으로 만듦
    function opHash(UserOperation op, address EntryPointAddr) private pure returns (bytes32 h) {
        uint256 chainId;

        assembly {
            chainId := chainId
        }

        h = keccak256(
            abi.encodePacked(
                chainId,
                EntryPointAddr,
                op.sender,
                op.nonce,
                op.initCode,
                op.callData,
                op.callGasLimit,
                op.verificationGasLimit,
                op.preVerificationGas,
                op.maxFeePerGas,
                op.maxPriorityFeePerGas,
                op.paymasterAndData
            )
        );
    }

    // 2번으로 만듦
    function validateOpHash(UserOperation op, address EntryPointAddr) private pure returns (address) {
        uint256 chainId;

        assembly {
            chainId := chainId
        }

        bytes32 h = keccak256(
            abi.encodePacked(
                chainId,
                EntryPointAddr,
                op.sender,
                op.nonce,
                op.initCode,
                op.callData,
                op.callGasLimit,
                op.verificationGasLimit,
                op.preVerificationGas,
                op.maxFeePerGas,
                op.maxPriorityFeePerGas,
                op.paymasterAndData
            )
        );


    }
}
