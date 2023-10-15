// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";

interface IAggregator {
    function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);

    function aggregateSignatures(UserOperation[] calldata userOps)
        external
        view
        returns (bytes memory aggregatesSignature);

    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;
}
