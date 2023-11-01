// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AA, IAA, UserOperation, UserOpLib} from "../src/AA.sol";
import "../src/IEntryPoint.sol";

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

    function getHash(UserOperation calldata op, address entryAddr) external view returns (bytes32 h) {
        h = op.hash(entryAddr);
    }
}

contract AccountTest is Test {
    HelperMock ohm;
    Accumulator acu;
    AA aa;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("SEPOLIA_RPC_URL"));
        ohm = new HelperMock();
        acu = new Accumulator();
        // AA의 소유권자 EOA를 등록합니다.
        aa = new AA(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    function testIntegrate() public {
        // AA에 이더를 담아둡니다.
        payable(aa).call{value: 1 ether}("");
        // EntryPoint를 실행할 EOA(Bundler)에 가스비로 사용할 이더를 넣어둡니다.
        payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266).call{value: 1 ether}("");

        // Bundler의 현재 밸런스를 확인합니다. 1.003000000000000000 ether
        console2.log(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266).balance);

        // AA의 execute 함수의 인자로 사용될 calldata를 정의합니다.
        IAA.Call memory c =
            IAA.Call({target: address(acu), value: 0, data: abi.encodeWithSelector(Accumulator.increase.selector)});

        UserOperation memory op = UserOperation({
            sender: address(aa),
            nonce: 0,
            initCode: "",
            // 앞서 준비한 calldata를 execute 함수 시그니쳐와 결합해줍니다
            callData: abi.encodeWithSignature("execute((address,uint256,bytes))", c),
            callGasLimit: 100_000,
            verificationGasLimit: 200_000,
            preVerificationGas: 60_000,
            maxFeePerGas: 126_174_846,
            maxPriorityFeePerGas: 100_000_000,
            paymasterAndData: "",
            signature: ""
        });

        // EntryPoint에 UserOperation을 배열로 주입하여야 하므로, 배열로 만들어줍니다.
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        // 만들어둔 UserOperation에 대해 해시하고 서명을 만들어줍니다.
        bytes32 opHash = ohm.getHash(op, address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789));
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80, opHash);
        op.signature = abi.encodePacked(r, s, v);

        // Bundler의 EOA로, UserOperation을 EntryPoint로 전송해줍니다.
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789).handleOps(ops, payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));

        // 가산기의 숫자가 1증가했는지 확인합니다.
        assertEq(acu.v(), 1);

        // Bundler의 최종 밸런스를 확인합니다. 1.003022039969749588 ether
        console2.log(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266).balance);
    }

    function testExecute() public {
        IAA.Call memory c =
            IAA.Call({target: address(acu), value: 0, data: abi.encodeWithSelector(Accumulator.increase.selector)});

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        aa.execute(c);

        assertEq(acu.v(), 1);
    }

    function testExecuteMulti() public {
        IAA.Call memory c =
            IAA.Call({target: address(acu), value: 0, data: abi.encodeWithSelector(Accumulator.increase.selector)});
        IAA.Call[] memory cs = new IAA.Call[](5);
        (cs[0], cs[1], cs[2], cs[3], cs[4]) = (c, c, c, c, c);

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        aa.execute(cs);

        assertEq(acu.v(), 5);
    }

    function testExecuteRaw() public {
        IAA.Call memory c =
            IAA.Call({target: address(acu), value: 0, data: abi.encodeWithSelector(Accumulator.increase.selector)});

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        // This is actually how EntryPoint calls Account.
        address(aa).call(abi.encodeWithSignature("execute((address,uint256,bytes))", c));

        assertEq(acu.v(), 1);
    }

    function testExecuteMultiRaw() public {
        IAA.Call memory c =
            IAA.Call({target: address(acu), value: 0, data: abi.encodeWithSelector(Accumulator.increase.selector)});
        IAA.Call[] memory cs = new IAA.Call[](5);
        (cs[0], cs[1], cs[2], cs[3], cs[4]) = (c, c, c, c, c);

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        // This is actually how EntryPoint calls Account.
        address(aa).call(abi.encodeWithSignature("execute((address,uint256,bytes)[])", cs));

        assertEq(acu.v(), 5);
    }

    function testValidateUserOp() public {
        UserOperation memory op = UserOperation({
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

        bytes32 opHash = ohm.getHash(op, address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789));
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80, opHash);

        op.signature = abi.encodePacked(r, s, v);

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        // 소유권자의 서명이 되었으므로, 성공해야 합니다.
        assertEq(aa.validateUserOp(op, opHash, 0), 0);
    }

    function testValidateUserOpNotFromOwner() public {
        UserOperation memory op = UserOperation({
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

        bytes32 opHash = ohm.getHash(op, address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789));
        // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d, opHash);

        op.signature = abi.encodePacked(r, s, v);

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        // 소유권자의 서명이 아니므로 실패해야 합니다.
        assertEq(aa.validateUserOp(op, opHash, 0), 1);
    }

    function testAddOwnerThroughExecute() public {
        address addTarget = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

        IAA.Call memory c =
            IAA.Call({target: address(aa), value: 0, data: abi.encodeWithSelector(IAA.addOwner.selector, addTarget)});

        assertEq(aa.owners(addTarget), false);

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        address(aa).call(abi.encodeWithSignature("execute((address,uint256,bytes))", c));

        assertEq(aa.owners(addTarget), true);
    }

    function testRemoveOwnerThroughExecute() public {
        address removeTarget = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        IAA.Call memory c = IAA.Call({
            target: address(aa),
            value: 0,
            data: abi.encodeWithSelector(IAA.removeOwner.selector, removeTarget)
        });

        assertEq(aa.owners(removeTarget), true);

        // Call from EntryPoint.
        vm.prank(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
        address(aa).call(abi.encodeWithSignature("execute((address,uint256,bytes))", c));

        assertEq(aa.owners(removeTarget), false);
    }

    function testAddOwnerCallFromNotSelf() public {
        address addTarget = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

        vm.expectRevert();
        aa.addOwner(addTarget);
    }

    function testRemoveOwnerCallFromNotSelf() public {
        address removeTarget = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.expectRevert();
        aa.removeOwner(removeTarget);
    }

    function testIsValidSignature() public {
        bytes32 opHash = keccak256("hello");
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80, opHash);

        bytes memory signature = abi.encodePacked(r, s, v);

        bytes memory target = abi.encode(0x1626ba7e00000000000000000000000000000000000000000000000000000000);
        bytes memory result = abi.encode(aa.isValidSignature(opHash, signature));

        assertEq(result, target);
    }

    function Address(string memory name) internal returns (address ret) {
        ret = address(uint160(uint256(keccak256(abi.encode(name)))));
        vm.label(ret, name);
    }
}
