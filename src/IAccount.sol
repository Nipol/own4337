// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";

interface IAccount {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);
}
