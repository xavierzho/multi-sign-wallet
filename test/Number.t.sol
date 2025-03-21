// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Number} from "./demo/Number.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ProxyTest is Test {
    // 代理合约
    ERC1967Proxy public proxy1;
    ERC1967Proxy public proxy2;
    // Number 合约的实现
    Number public numberImplementation;
    // 管理员账户
    address public admin;
    // 存储插槽，用于存储 Number 合约的地址
    bytes32 constant implementationSlot =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        // 部署 Number 合约
        numberImplementation = new Number();
        // 设置管理员账户
        admin = address(this);
        // 部署两个代理合约，并将管理员设置为调用者
        proxy1 = new ERC1967Proxy(address(numberImplementation), abi.encodePacked(bytes4(keccak256("initialize(uint256)")), uint256(100)));
        proxy2 = new ERC1967Proxy(address(numberImplementation), abi.encodePacked(bytes4(keccak256("initialize(uint256)")), uint256(100)));
    }

    // 获取代理合约中 value 状态变量的辅助函数
    function getValue(address _proxy) internal returns (uint256 value) {
        (bool success, bytes memory returnData) = _proxy.call(
            abi.encodeWithSignature("value()")
        );
        require(success, "Failed to get value");
        value = abi.decode(returnData, (uint256));
    }

    // 设置代理合约中 value 状态变量的辅助函数
    function setValue(address _proxy, uint256 _value) internal {
        (bool success, bytes memory returnData) = _proxy.call(
            abi.encodeWithSignature("set(uint256)", _value)
        );
        require(success, "Failed to set value");
    }

    // 测试：代理合约部署
//    function test_ProxyDeployment() public {
//        // 验证代理合约是否已部署
//        assertNotEq(address(proxy1), address(0), "Proxy1 not deployed");
//        assertNotEq(address(proxy2), address(0), "Proxy2 not deployed");
//        // 验证代理合约的实现合约地址是否正确
//        address implementation1 = getImplementation(address(proxy1));
//        address implementation2 = getImplementation(address(proxy2));
//        assertEq(
//            implementation1,
//            address(numberImplementation),
//            "Incorrect implementation for Proxy1"
//        );
//        assertEq(
//            implementation2,
//            address(numberImplementation),
//            "Incorrect implementation for Proxy2"
//        );
//    }

    // 测试：初始状态
    function test_InitialState() public {
        // 验证两个代理合约的初始值是否都为 100
        uint256 value1 = getValue(address(proxy1));
        uint256 value2 = getValue(address(proxy2));
        assertEq(value1, 100, "Incorrect initial value for Proxy1");
        assertEq(value2, 100, "Incorrect initial value for Proxy2");
    }

    // 测试：状态隔离
    function test_StateIsolation() public {
        // 通过 proxy1 设置 value
        setValue(address(proxy1), 200);
        // 验证 proxy1 的 value 是否已更新
        uint256 value1 = getValue(address(proxy1));
        assertEq(value1, 200, "Value not updated for Proxy1");
        // 验证 proxy2 的 value 是否保持不变
        uint256 value2 = getValue(address(proxy2));
        assertEq(value2, 100, "Value should not have changed for Proxy2");

        // 通过 proxy2 设置 value
        setValue(address(proxy2), 300);
        // 验证 proxy2 的 value 是否已更新
        value2 = getValue(address(proxy2));
        assertEq(value2, 300, "Value not updated for Proxy2");
        // 验证 proxy1 的 value 是否保持不变
        value1 = getValue(address(proxy1));
        assertEq(value1, 200, "Value should not have changed for Proxy1");
    }

    // 辅助函数：从代理合约的存储中获取实现合约的地址
    function getImplementation(address _proxy)
    internal
    view
    returns (address implementation)
    {
        bytes32 slot = implementationSlot;
        assembly {
            implementation := sload(slot)
        }
    }
}

