// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./UserOpLib.sol";
import "./IAccount.sol";

contract Account is IAccount {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // is caller EntryPoint?

        // is Account support `Signature Aggregation`?

        // is Sig Validation
    }
}
