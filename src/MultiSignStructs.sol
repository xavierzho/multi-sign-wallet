// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract MultiSignStructs {
    // Structs
    struct Transaction {
        address destination;       // Target address of the transaction (could be token contract or ETH receiver)
        uint256 value;             // Amount of Ether to send (ETH-only transactions)
        bytes data;                // Transaction data payload (e.g., function call data)
        bool executed;             // Execution status flag
        uint256 signatures;        // Number of collected signatures
    }

}
