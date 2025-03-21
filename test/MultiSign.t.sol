// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/MultiSign.sol";
import {MultiSigWallet} from "../src/MultiSign.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract MultiSignTest is Test {
    ERC1967Proxy public multiSignProxy; // Use ERC1967Proxy
    MultiSigWallet public multiSignLogic; //  Declare logic contract
    MultiSigWallet public multiSignWallet;
    address[] public accounts;
    address[] public owners;
    uint256 public requiredSignatures;
    address public admin; // Add admin

    function setUp() public {
        string memory mnemonic = "test test test test test test test test test test test junk";
        owners = new address[](3);
        for (uint256 i = 0; i < 10; ++i) {
            (address account,) = deriveRememberKey(mnemonic, uint32(i));
            accounts.push(account);
            if (i < 3) owners[i] = account;
        }
        requiredSignatures = 2;
        admin = accounts[9]; // Designate an admin

        // Deploy the logic contract
        multiSignLogic = new MultiSigWallet();

        // Deploy the proxy, passing the logic contract address and initialization data
        bytes memory initializeData = abi.encodeWithSignature(
            "initialize(address[],uint256)",
            owners,
            requiredSignatures
        );
        multiSignProxy = new ERC1967Proxy(address(multiSignLogic), initializeData);

        // Cast the proxy to the logic contract's ABI for easier interaction
        multiSignWallet = MultiSigWallet(payable(multiSignProxy));
    }

    // Helper: Verify event emission by signature
    function assertEventEmitted(
        bytes32 expectedEventSignature,
        bytes memory actualLog
    ) internal pure {
        bytes32 actualEventSignature;
        assembly {
            actualEventSignature := mload(add(actualLog, 0x14)) // Extract signature from log data
        }
        assertEq(
            actualEventSignature,
            expectedEventSignature,
            "Event signature mismatch"
        );
    }

    // Test: Verify contract initialization parameters
    function test_Deployment() public view {
        assertEq(multiSignWallet.requiredSignatures(), requiredSignatures, "Incorrect required signatures");
        for (uint256 i = 0; i < owners.length; i++) {
            assertTrue(multiSignWallet.isOwner(owners[i]), "Owner not set correctly");
        }
    }

    // Test: ETH deposit functionality
    function test_Deposit() public payable {
        uint256 amount = 1 ether;
        address sender = address(this); // Use test contract as sender
        vm.deal(sender, amount); // Fund test contract
        vm.startPrank(sender);
        (bool success,) = address(multiSignProxy).call{value: amount}("");
        require(success, "transfer failed");
        emit log_uint(address(multiSignProxy).balance);
        vm.stopPrank();

        assertEq(multiSignWallet.getBalance(), amount, "Incorrect contract balance");
    }

    // Test: Transaction proposal creation
    function test_SubmitTransaction() public {
        address destination = address(0x1234567890123456789012345678901234567890); // Sample destination
        uint256 value = 0.5 ether;
        bytes memory data = ""; // Empty payload
        address sender = owners[0];

        vm.startPrank(sender);
        bytes32 txId = multiSignWallet.createProposal(destination, value, data);
        vm.stopPrank();

        (address _destination, uint256 _value,bytes memory _data, bool executed,) = multiSignWallet.transactions(txId);
        assertEq(_destination, destination, "Incorrect destination");
        assertEq(_value, value, "Incorrect value");
        assertEq(_data, data, "Incorrect data");
        assertFalse(executed, "Transaction should not be executed");

        // Check ProposalSubmitted event emission
        // (commented out event verification)
    }

    // Test: Transaction confirmation process
    function test_ConfirmTransaction() public {
        address destination = accounts[4]; // External address
        uint256 value = 0.5 ether;
        bytes memory data = "";
        address sender1 = owners[0];
        address sender2 = owners[1];
//        payable(multiSignProxy).transfer(value);
        (bool success,) = address(multiSignProxy).call{value: value}("");
        require(success, "transfer failed");

        // Create proposal
        vm.startPrank(sender1);
        bytes32 txId = multiSignWallet.createProposal(destination, value, data);
        vm.stopPrank();

        // First confirmation
        vm.startPrank(sender1);
        multiSignWallet.confirmTransaction(txId);
        vm.stopPrank();
        (,,, bool executed, uint256 signatures) = multiSignWallet.transactions(txId);
        assertEq(signatures, 1, "Initial signature count mismatch");

        // Second confirmation
        vm.startPrank(sender2);
        multiSignWallet.confirmTransaction(txId);
        vm.stopPrank();
        (,,, executed, signatures) = multiSignWallet.transactions(txId);
        assertEq(signatures, 2, "Final signature count mismatch");
        assertTrue(executed, "Execution status mismatch");
    }

    // Test: Signature revocation mechanism
    function test_RevokeTransaction() public {
        address destination = accounts[4];
        uint256 value = 0.5 ether;
        bytes memory data = "";
        address sender1 = owners[0];

        // Create and confirm proposal
        vm.startPrank(sender1);
        bytes32 txId = multiSignWallet.createProposal(destination, value, data);
        multiSignWallet.confirmTransaction(txId);
        vm.stopPrank();

        // Revoke signature
        vm.startPrank(sender1);
        multiSignWallet.revokeProposal(txId);
        vm.stopPrank();

        (,,,, uint256 signatures) = multiSignWallet.transactions(txId);
        assertEq(signatures, 0, "Signature count after revocation mismatch");
    }

    // Test: Owner management - addition
    function test_AddOwner() public {
        address newOwner = accounts[4];
        address sender = owners[0];

        vm.startPrank(sender);
        multiSignWallet.addOwner(newOwner);
        vm.stopPrank();

        assertTrue(multiSignWallet.isOwner(newOwner), "Owner addition verification failed");
    }

    // Test: Owner management - removal
    function test_RemoveOwner() public {
        address oldOwner = owners[0];
        address sender = owners[1]; // Different owner initiates removal

        vm.startPrank(sender);
        multiSignWallet.removeOwner(oldOwner);
        vm.stopPrank();

        assertFalse(multiSignWallet.isOwner(oldOwner), "Owner removal verification failed");
    }

    // Test: Signature threshold adjustment
    function test_ChangeRequirement() public {
        uint256 newRequirement = 1;
        address sender = owners[0];

        vm.startPrank(sender);
        multiSignWallet.changeRequirement(newRequirement);
        vm.stopPrank();

        assertEq(multiSignWallet.requiredSignatures(), newRequirement, "Requirement update verification failed");
    }

    // Test: Access control validation
    function test_OnlyOwnerModifier() public {
        address nonOwner = address(0x9876543210987654321098765432109876543210);
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("NotOwner()"));
        multiSignWallet.addOwner(nonOwner); // Attempt restricted operation
        vm.stopPrank();
    }
}
