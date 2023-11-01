// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./UserOpLib.sol";
import "./IERC165.sol";
import "./IEntryPoint.sol";
import "./IAA.sol";
import "./IERC1271.sol";

contract AA is IAA, IERC1271 {
    mapping(address => bool) public owners;

    constructor(address anOwner) {
        owners[anOwner] = true;
    }

    receive() external payable {}

    function execute(Call calldata call) public returns (bytes memory returnData) {
        if (msg.sender != 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789) revert();

        (bool success, bytes memory result) = call.target.call{value: call.value}(call.data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(32, result), mload(result))
            }
        }

        returnData = result;
    }

    function execute(Call[] calldata calls) public returns (bytes[] memory returnData) {
        if (msg.sender != 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789) revert();

        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call calldata calli;
        for (uint256 i; i != length;) {
            calli = calls[i];
            (bool success, bytes memory result) = calli.target.call{value: calli.value}(calli.data);
            if (!success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, result), mload(result))
                }
            }

            returnData[i] = result;

            unchecked {
                ++i;
            }
        }
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // is caller EntryPoint?
        if (msg.sender != 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789) revert();

        if (missingAccountFunds != 0) {
            payable(msg.sender).call{value: missingAccountFunds, gas: type(uint16).max}("");
        }

        // is this Account support `Signature Aggregation`? for Now. No.
        uint8 v;
        bytes32 r;
        bytes32 s;

        // for easy accesible.
        bytes calldata signature = userOp.signature;

        if (signature.length != 65) return 1;

        assembly {
            calldatacopy(mload(0x40), signature.offset, 0x20)
            calldatacopy(add(mload(0x40), 0x20), add(signature.offset, 0x20), 0x20)
            calldatacopy(add(mload(0x40), 0x5f), add(signature.offset, 0x40), 0x2)

            // check signature malleability
            if gt(mload(add(mload(0x40), 0x20)), 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                mstore(0x0, 0x01)
                return(0x0, 0x20)
            }

            r := mload(mload(0x40))
            s := mload(add(mload(0x40), 0x20))
            v := mload(add(mload(0x40), 0x40))
        }

        if (!owners[ecrecover(userOpHash, v, r, s)]) return 1;

        // packing authorizer(0 for valid signature, 1 to mark signature failure.
        // Otherwise, an address of an authorizer contract. This ERC defines “signature aggregator” as authorizer.),
        // validUntil(6 bytes) and validAfter(6 bytes)
        return 0;
    }

    function addOwner(address anOwner) external {
        if (msg.sender != address(this)) revert();

        owners[anOwner] = true;
    }

    function removeOwner(address anOwner) external {
        if (msg.sender != address(this)) revert();

        delete owners[anOwner];
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue) {
        if (_signature.length != 65) return 0xffffffff;

        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            calldatacopy(mload(0x40), _signature.offset, 0x20)
            calldatacopy(add(mload(0x40), 0x20), add(_signature.offset, 0x20), 0x20)
            calldatacopy(add(mload(0x40), 0x5f), add(_signature.offset, 0x40), 0x2)

            // check signature malleability
            if gt(mload(add(mload(0x40), 0x20)), 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                mstore(0x0, 0x01)
                return(0x0, 0x20)
            }

            r := mload(mload(0x40))
            s := mload(add(mload(0x40), 0x20))
            v := mload(add(mload(0x40), 0x40))
        }

        if (!owners[ecrecover(_hash, v, r, s)]) return 0xffffffff;

        return 0x1626ba7e;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0xbc197c81;
    }
}
