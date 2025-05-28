// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge script script/AnvilDeploy.s.sol:AnvilDeploy --rpc-url http://localhost:8545 --broadcast

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";

contract AnvilDeploy is Script {
    function run() external {
        // Get the private key from the command line
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock LINK token
        MockLinkToken linkToken = new MockLinkToken();

        // Deploy mock VRF Coordinator
        // Parameters: base fee, gas price link
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            0.1 ether, // base fee
            1e9 // gas price link
        );

        // Create a subscription for the raffle contract
        uint64 subId = vrfCoordinator.createSubscription();
        
        // Deploy Raffle contract with all required parameters
        Raffle raffle = new Raffle(
            subId, // subscription ID
            bytes32(uint256(1)), // keyHash (using a dummy value for testing)
            deployer, // platform wallet (using deployer address)
            address(vrfCoordinator) // VRF coordinator address
        );

        // Add the raffle contract as a consumer
        vrfCoordinator.addConsumer(subId, address(raffle));

        // Transfer LINK tokens to the VRF Coordinator
        linkToken.transfer(address(vrfCoordinator), 2 ether);

        // Fund the subscription
        vrfCoordinator.fundSubscription(subId, 2 ether);

        vm.stopBroadcast();

        // Log the deployed addresses and network info
        console.log("Network ID:", block.chainid);
        console.log("Deployer address:", deployer);
        console.log("LinkToken deployed to:", address(linkToken));
        console.log("VRFCoordinatorV2Mock deployed to:", address(vrfCoordinator));
        console.log("Raffle deployed to:", address(raffle));
        console.log("Subscription ID:", subId);
        
        // Log the addresses in a format that's easy to copy
        console.log("\nContract Addresses (copy-paste format):");
        console.log("LINK_TOKEN=%s", address(linkToken));
        console.log("VRF_COORDINATOR=%s", address(vrfCoordinator));
        console.log("RAFFLE=%s", address(raffle));
    }
} 