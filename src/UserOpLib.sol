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
    function hash(UserOperation calldata op, address EntryPointAddr) internal view returns (bytes32 h) {
        // stored chainid
        uint256 chainId;

        // load chainid
        assembly {
            chainId := chainid()
        }

        h = keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        op.sender,
                        op.nonce,
                        keccak256(op.initCode),
                        keccak256(op.callData),
                        op.callGasLimit,
                        op.verificationGasLimit,
                        op.preVerificationGas,
                        op.maxFeePerGas,
                        op.maxPriorityFeePerGas,
                        keccak256(op.paymasterAndData)
                    )
                ),
                EntryPointAddr,
                chainId
            )
        );
        // assembly {
        //     mstore(0x00, "\x19Ethereum Signed Message:\n32")
        //     mstore(0x1c, h)
        //     h := keccak256(0x00, 0x3c)
        // }
    }

    /**
     * @notice  Executes the given `UserOperation` as a `call`.
     * @dev     Later, we'll need to get the value from calldata and use it directly.
     * @param   op              UserOperation struct
     * @return  success         Success or failure
     */
    function call(UserOperation calldata op) internal returns (bool success) {
        address sender = op.sender;
        bytes memory data = op.callData;
        uint256 callGasLimit = op.callGasLimit;

        assembly {
            success := call(callGasLimit, sender, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }
}
