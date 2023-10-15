// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";

library UserOpLib {
    /**
     * @notice  Generate a unique hash for an Operation based on a given `UserOperation` structure,
     *          `Entrypoint` address, and `chainid`.
     * @param   op              UserOperation struct
     * @param   EntryPointAddr  Entrypoint Contract Address
     * @return  h               Unique UserOperation hash.
     */
    function opHash(UserOperation calldata op, address EntryPointAddr) internal view returns (bytes32 h) {
        // stored chainid
        uint256 chainId;

        // load chainid
        assembly {
            chainId := chainid()
        }

        // hashing
        h = keccak256(
            // concat data without signature(Too deep. use viaIr)
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
    function validateUserOp(UserOperation calldata op, address EntryPointAddr) internal view returns (address) {
        uint256 chainId;

        assembly {
            chainId := chainid()
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
