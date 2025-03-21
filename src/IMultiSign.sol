// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IMultiSign {
    // Events
    event Deposit(address indexed sender, uint256 value);          // Emitted when Ether is deposited
    event ProposalSubmitted(bytes32 indexed txId, address destination, uint256 value, bytes data); // New transaction proposal
    event ProposalRevoked(bytes32 indexed txId);                   // Transaction proposal revoked
    event TransactionConfirmed(bytes32 indexed txId, address owner); // Signature collected for transaction
    event TransactionExecuted(bytes32 indexed txId);              // Transaction successfully executed
    event OwnerAdded(address indexed newOwner);                    // New owner added
    event OwnerRemoved(address indexed oldOwner);                  // Owner removed
    event RequirementChanged(uint256 newRequirement);              // Signature requirement changed

    // Errors
    error NotOwner();               // Caller is not an owner
    error AlreadyOwner();           // Address is already an owner
    error TooFewSignatures();       // Insufficient signatures collected
    error TransactionNotFound();    // Transaction ID does not exist
    error AlreadySigned();          // Owner already signed this transaction
    error TransactionAlreadyExecuted(); // Transaction has already been executed
    error InvalidRequirement();     // Invalid signature requirement value
    error NotEnoughBalance();       // Insufficient contract balance

    function createProposal(address _destination, uint256 _value, bytes memory _data) external returns (bytes32 _txId);
    function revokeProposal(bytes32 _txId) external;
    function confirmTransaction(bytes32 _txId) external;

    function addSigner(address _newSigner) external;
    function removeSigner(address _oldSigner) external;
}
