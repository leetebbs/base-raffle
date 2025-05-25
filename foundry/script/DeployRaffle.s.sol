// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    // Chainlink VRF configuration
    // These values should be updated based on the target network
    // See https://docs.chain.link/vrf/v2/subscription/supported-networks
    uint256 constant BASE_SEPOLIA_SUBSCRIPTION_ID = 38383525125522053884647515819193010196348704191534090826444481815518132313372; 
    bytes32 constant BASE_SEPOLIA_KEY_HASH = 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71; 
    address constant BASE_SEPOLIA_VRF_COORDINATOR = 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE; 

    // Platform configuration
    address constant PLATFORM_WALLET = 0x1ABc133C222a185fEde2664388F08ca12C208F76; // Replace with your platform wallet address

    function run() external returns (Raffle) {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the Raffle contract
        Raffle raffle = new Raffle(
            BASE_SEPOLIA_SUBSCRIPTION_ID,
            BASE_SEPOLIA_KEY_HASH,
            PLATFORM_WALLET,
            BASE_SEPOLIA_VRF_COORDINATOR
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log deployment information
        console.log("Raffle contract deployed at:", address(raffle));
        console.log("Contract owner:", raffle.contractOwner());
        console.log("VRF Subscription ID:", raffle.s_subscriptionId());
        
        return raffle;
    }
}