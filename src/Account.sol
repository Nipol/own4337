// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./UserOpLib.sol";
import "./IERC165.sol";
import "./IEntryPoint.sol";
import "./IAccount.sol";

contract Account is IAccount {
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // is caller EntryPoint?
        if (IERC165(msg.sender).supportsInterface(type(IEntryPoint).interfaceId) != true) revert();

        if (missingAccountFunds != 0) {
            payable(msg.sender).transfer(missingAccountFunds);
        }

        // is this Account support `Signature Aggregation`? for Now. No.
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (userOp.signature.length != 65) revert();

        // for easy accesible.
        bytes calldata signature = userOp.signature;

        assembly {
            calldatacopy(mload(0x40), signature.offset, 0x20)
            calldatacopy(add(mload(0x40), 0x20), add(signature.offset, 0x20), 0x20)
            calldatacopy(add(mload(0x40), 0x5f), add(signature.offset, 0x40), 0x2)

            // check signature malleability
            if gt(mload(add(mload(0x40), 0x20)), 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                revert(0x0, 0x4)
            }

            r := mload(mload(0x40))
            s := mload(add(mload(0x40), 0x20))
            v := mload(add(mload(0x40), 0x40))
        }

        address recovered = ecrecover(userOpHash, v, r, s);

        // packing authorizer(0 for valid signature, 1 to mark signature failure.
        // Otherwise, an address of an authorizer contract. This ERC defines “signature aggregator” as authorizer.),
        // validUntil(6 bytes) and validAfter(6 bytes)
        return 0;
    }
}
