// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script, console} from "forge-std/Script.sol";

import {MultiSigWallet} from "../src/MultiSign.sol";
import {ERC1967Proxy} from "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MultiSignScript is Script{
    function setUp() public {}


    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        MultiSigWallet multiSignLogic = new MultiSigWallet();

        bytes memory initializeData = abi.encodeWithSignature(
            "initialize(address[],uint256)",
            vm.envAddress("OWNERS", ","),
            vm.envUint("REQUIRED_SIGNATURES")
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(multiSignLogic), initializeData);
        console.log("Deployed MultiSignWallet logic:%s", address(multiSignLogic));
        console.log("Deployed MultiSignWallet proxy: %s", address(proxy));
        vm.stopBroadcast();
    }
}
