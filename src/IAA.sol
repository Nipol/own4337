// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";

interface IAA {
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);

    function addOwner(address anOwner) external;

    function removeOwner(address anOwner) external;
}
