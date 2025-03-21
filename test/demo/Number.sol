// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Number  is Initializable {

    uint256 public value;

    function initialize(uint256 _value) public initializer{
        value = _value;
    }


    function set(uint256 _value) public  {
        value = _value;
    }
}
