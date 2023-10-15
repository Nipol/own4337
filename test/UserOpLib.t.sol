// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/UserOpLib.sol";

contract HelperMock {
    using UserOpLib for UserOperation;

    function getHash(UserOperation calldata op, address entryAddr) external view returns (bytes32 h) {
        h = op.opHash(entryAddr);
    }
}

contract UserOperationHelperTest is Test {
    UserOperation op1;
    UserOperation op2;
    HelperMock ohm;

    function setUp() public {
        op1 = UserOperation({
            sender: Address("Sender"),
            nonce: 0,
            initCode: abi.encode(0),
            callData: abi.encode(0),
            callGasLimit: 0,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: abi.encode(0),
            signature: abi.encode(0)
        });

        op2 = UserOperation({
            sender: Address("Another Sender"),
            nonce: 0,
            initCode: abi.encode(0),
            callData: abi.encode(0),
            callGasLimit: 0,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: abi.encode(0),
            signature: abi.encode(0)
        });
        ohm = new HelperMock();
    }

    function Address(string memory name) internal returns (address ret) {
        ret = address(uint160(uint256(keccak256(abi.encode(name)))));
        vm.label(ret, name);
    }

    function testHash() public {
        UserOperation memory op = op1;
        // base
        emit log_uint(block.chainid);
        bytes32 h = ohm.getHash(op, Address("EntryPoint"));
        assertEq(h, 0x703b673b8562624140ecc3e1d3a7fe0a0ce9e511dfebb90e27a37140a08b394a);

        // chanage chainid
        vm.chainId(999);
        emit log_uint(block.chainid);
        h = ohm.getHash(op, Address("EntryPoint"));
        assertEq(h, 0x512faaea96afd35c2a0f8f2a3fa3963a06769da4a64069efcc330df8c7f175ec);

        // chanage Entrypoint addr
        h = ohm.getHash(op, Address("Another EntryPoint"));
        assertEq(h, 0xe9ba5bc83fc204a07cf299be67a5c912c761a8c88ae534fb148c900a4194745c);
    }
}
