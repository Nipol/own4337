// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/UserOpLib.sol";

contract Accumulator {
    uint256 public v;
    address public caller;

    function increase() external {
        v += 1;
        caller = msg.sender;
    }
}

contract HelperMock {
    using UserOpLib for UserOperation;

    function execute(UserOperation calldata op) external {
        if (!op.call()) revert();
    }

    function getHash(UserOperation calldata op, address entryAddr) external view returns (bytes32 h) {
        h = op.hash(entryAddr);
    }
}

contract UserOperationHelperTest is Test {
    UserOperation op1;
    UserOperation op2;
    HelperMock ohm;
    Accumulator a;

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
        ohm = new HelperMock();
        a = new Accumulator();
        op2 = UserOperation({
            sender: address(a),
            nonce: 0,
            initCode: abi.encode(0),
            callData: abi.encodeWithSelector(Accumulator.increase.selector),
            callGasLimit: 200000,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: abi.encode(0),
            signature: abi.encode(0)
        });
    }

    function Address(string memory name) internal returns (address ret) {
        ret = address(uint160(uint256(keccak256(abi.encode(name)))));
        vm.label(ret, name);
    }

    function testHash() public {
        UserOperation memory op = op1;
        // base
        bytes32 h = ohm.getHash(op, Address("EntryPoint"));
        assertEq(h, 0x2678d5fc1f0bf2149884cfafe702897e8d32f014c800087953ce9c07d65bba3b);

        // chanage chainid
        vm.chainId(999);
        h = ohm.getHash(op, Address("EntryPoint"));
        assertEq(h, 0xfca1d7caba47d6fa3846dd375172d6bafaae0aab99a82a8dfd4d2b19d1cb7f7e);

        // chanage Entrypoint addr
        h = ohm.getHash(op, Address("Another EntryPoint"));
        assertEq(h, 0x456922b0db5a29bbafc3d6a30278a9ef71395ef42647ce9d583532d0a7fa1d46);
    }

    function testCall() public {
        UserOperation memory op = op2;

        ohm.execute(op);

        assertEq(a.v(), 1);
    }
}
