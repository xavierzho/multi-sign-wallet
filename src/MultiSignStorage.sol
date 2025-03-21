// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {MultiSignStructs} from "./MultiSignStructs.sol";

contract MultiSignStorage is  MultiSignStructs{
    // State Variables
    mapping(address => bool) public isOwner;       // Mapping from address to owner status
    uint256 public requiredSignatures;            // Number of required signatures to execute a transaction
    mapping(bytes32 => MultiSignStructs.Transaction) public transactions; // Stores transaction details
    mapping(bytes32 => mapping(address => bool)) public hasSigned; // Tracks which owners have signed which transactions
    address[] public owners;                      // List of owner addresses (maintains insertion order)

    uint256 public transactionCount;              // Total transaction count for generating unique transaction IDs

}
