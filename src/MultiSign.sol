// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {MultiSignStorage} from "./MultiSignStorage.sol";
import {IMultiSign} from "./IMultiSign.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Multi-Signature Wallet
 * @author zzzz
 * @dev Allows a group of owners to manage funds and execute transactions.
 */
contract MultiSigWallet is Initializable, MultiSignStorage, IMultiSign {

    /**
     * @dev Initializes the multi-signature wallet
     * @param _owners Initial list of owners
     * @param _requiredSignatures Minimum signatures required to execute transactions
     */

    function initialize(address[] memory _owners, uint256 _requiredSignatures) public initializer {
        // Validate owners list
        require(_owners.length > 0, "Empty owners list");
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length, "Invalid signature requirement");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert("Zero address prohibited");
            if (isOwner[owner]) revert("Duplicate owner detected");

            isOwner[owner] = true;
            owners.push(owner); // Store the owner
        }
        requiredSignatures = _requiredSignatures;
    }
    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Submits a new transaction proposal
     * @param _destination Target contract/address
     * @param _value Ether amount to send
     * @param _data Transaction payload data
     * @return txId Generated transaction ID
     */
    function createProposal(address _destination, uint256 _value, bytes memory _data) public onlyOwner returns (bytes32 txId) {
        txId = keccak256(abi.encodePacked(_destination, _value, _data, transactionCount));
        transactionCount++;

        if (transactions[txId].destination != address(0) || transactions[txId].data.length != 0) {
            revert("Transaction ID collision detected");
        }

        transactions[txId] = Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false,
            signatures: 0
        });
        emit ProposalSubmitted(txId, _destination, _value, _data);
    }

    /**
     * @dev Confirms a transaction by providing signature
     * @param _txId Transaction ID to confirm
     */
    function confirmTransaction(bytes32 _txId) public onlyOwner {
        Transaction storage tx_ = transactions[_txId];
        if (tx_.destination == address(0)) revert TransactionNotFound();
        if (tx_.executed) revert TransactionAlreadyExecuted();
        if (hasSigned[_txId][msg.sender]) revert AlreadySigned();

        hasSigned[_txId][msg.sender] = true;
        tx_.signatures++;
        emit TransactionConfirmed(_txId, msg.sender);

        if (tx_.signatures >= requiredSignatures) {
            executeTransaction(_txId);
        }
    }

    /**
     * @dev Executes a confirmed transaction
     * @param _txId Transaction ID to execute
     */
    function executeTransaction(bytes32 _txId) private {
        Transaction storage tx_ = transactions[_txId];
        if (tx_.destination == address(0)) revert TransactionNotFound();
        if (tx_.executed) revert TransactionAlreadyExecuted();
        if (tx_.signatures < requiredSignatures) revert TooFewSignatures();

        Transaction storage localTx = transactions[_txId];
        localTx.executed = true; // 先标记为已执行，防止重入
        bool success;
        bytes memory returnData;
        if (localTx.value > 0) {
            (success, returnData) = tx_.destination.call{value: localTx.value}(localTx.data);
        } else {
            (success, returnData) = tx_.destination.call(localTx.data);
        }
        require(success, "low-level call tx failed");

        emit TransactionExecuted(_txId);
    }

    /**
     * @dev Modifier restricting function access to owners only
     */
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    /**
     * @dev Revokes a signature from a pending transaction
     * @param _txId Transaction ID to revoke
     */
    function revokeProposal(bytes32 _txId) public onlyOwner {
        Transaction storage tx_ = transactions[_txId];
        if (tx_.destination == address(0)) revert TransactionNotFound();
        if (tx_.executed) revert TransactionAlreadyExecuted();
        if (!hasSigned[_txId][msg.sender]) revert("Signature not found");

        hasSigned[_txId][msg.sender] = false;
        tx_.signatures--;
        emit ProposalRevoked(_txId);
    }

    /**
     * @dev Adds a new owner to the wallet
     * @param _newOwner Address of the new owner
     */
    function addOwner(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) revert("Invalid zero address");
        if (isOwner[_newOwner]) revert AlreadyOwner();

        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        emit OwnerAdded(_newOwner);

        // Auto-adjust requirement if needed
        if (owners.length < requiredSignatures) {
            requiredSignatures = owners.length;
            emit RequirementChanged(requiredSignatures);
        }
    }

    /**
     * @dev Removes an existing owner
     * @param _oldOwner Address of the owner to remove
     */
    function removeOwner(address _oldOwner) public onlyOwner {
        if (!isOwner[_oldOwner]) revert NotOwner();
        if (owners.length == 1) revert("Cannot remove last owner");

        isOwner[_oldOwner] = false;

        // Remove from owners array
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _oldOwner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        emit OwnerRemoved(_oldOwner);

        // Auto-adjust requirement if needed
        if (owners.length < requiredSignatures) {
            requiredSignatures = owners.length;
            emit RequirementChanged(requiredSignatures);
        }
    }

    /**
     * @dev Updates the required signature threshold
     * @param _newRequirement New signature requirement
     */
    function changeRequirement(uint256 _newRequirement) public onlyOwner {
        if (_newRequirement == 0 || _newRequirement > owners.length) revert InvalidRequirement();
        requiredSignatures = _newRequirement;
        emit RequirementChanged(_newRequirement);
    }

    /**
     * @dev Returns contract's Ether balance
     * @return Current balance in wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns list of current owners
     * @return Array of owner addresses
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev Checks if an owner has signed a specific transaction
     * @param _txId Transaction ID to check
     * @param _owner Owner address to verify
     * @return True if owner has signed
     */
    function isTransactionSigned(bytes32 _txId, address _owner) public view returns (bool) {
        return hasSigned[_txId][_owner];
    }
}
