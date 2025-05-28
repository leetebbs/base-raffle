// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Raffle copy.sol"; // Import the modified contract
import "../../src/MockERC721.sol";
import { VRFCoordinatorV2_5Mock } from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest2 is Test {
    Raffle raffle;
    MockERC721 nft;
    VRFCoordinatorV2_5Mock vrf;
    address owner = address(0x1);
    address platform = address(0x2);
    address alice = address(0x3);
    address bob = address(0x4);

    uint256 constant SUB_ID = 1;
    bytes32 constant KEY_HASH = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    uint256 constant TOKEN_ID = 42;

    // Chainlink VRF Mock parameters
    uint96 constant BASE_FEE = 0.1 ether; // Example base fee
    uint96 constant GAS_PRICE_LINK = 1e9; // Example gas price
    int256 constant FULFILL_GAS_LIMIT = 500000; // Example fulfill gas limit

    uint256 subId;

    function setUp() public {
        owner = address(0x1);
        platform = address(0x2);
        alice = address(0x3);
        bob = address(0x4);
        
        // Deploy Mock VRFCoordinatorV2_5Mock (used in VRFConsumerBaseV2Plus)
        vm.startPrank(owner);
        vrf = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE_LINK, FULFILL_GAS_LIMIT);
        vm.stopPrank();

        // Create a new subscription
        vm.startPrank(owner);
        subId = vrf.createSubscription();
        vm.stopPrank();

        // Fund the subscription
        vm.deal(owner, 10 ether);
        vm.startPrank(owner);
        vrf.fundSubscription(subId, 10 ether);
        vm.stopPrank();

        // Deploy Raffle contract
        vm.startPrank(owner);
        raffle = new Raffle(subId, KEY_HASH, platform, address(vrf));
        vm.stopPrank();

        // ** Add Raffle contract as a consumer **
        vm.startPrank(owner);
        vrf.addConsumer(subId, address(raffle));
        vm.stopPrank();

        // Mint NFT to owner
        vm.startPrank(owner);
        nft = new MockERC721("MockNFT", "MNFT");
        nft.mint(owner, TOKEN_ID);
        nft.mint(owner, TOKEN_ID + 1);
        vm.stopPrank();
    }

    function test_processWinnerPayouts_featuredRaffle() public {
        // Create a FEATURED raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5,
            true // Set featured to true
        );
        vm.stopPrank();

        // Alice buys 5 tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Bob buys 5 tickets
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Get initial balances
        uint256 aliceInitialBalance = alice.balance;
        uint256 platformInitialBalance = platform.balance;
        uint256 ownerInitialBalance = owner.balance;

        // Mock VRF callback with a random word that will select Alice as winner
        // We'll use a random word that will result in index 0-4 (Alice's tickets)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 2; // This will select index 2, which is one of Alice's tickets

        // Get the request ID from the raffle
        uint256 requestId = raffle.getRaffleInfo(0).requestId;

        // Mock the VRF callback by calling rawFulfillRandomWords directly on the Raffle contract
        vm.prank(address(vrf));
        raffle.rawFulfillRandomWords(requestId, randomWords);

        // Calculate expected payouts for a FEATURED raffle
        uint256 totalPrize = 10 ether;
        uint256 platformFee = (totalPrize * 20) / 100; // 20% platform fee for featured
        uint256 winnerPrize = (totalPrize * 10) / 100; // 10% winner fee
        uint256 creatorPayout = totalPrize - platformFee - winnerPrize; // Remaining for creator

        // Verify balances after payouts
        assertEq(alice.balance, aliceInitialBalance + winnerPrize, "Alice should receive winner prize");
        assertEq(platform.balance, platformInitialBalance + platformFee, "Platform should receive 20% fee for featured raffle");
        assertEq(owner.balance, ownerInitialBalance + creatorPayout, "Owner should receive creator payout");

        // Verify NFT transfer
        assertEq(nft.ownerOf(TOKEN_ID), alice, "NFT should be transferred to winner");

        // Verify raffle state
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);
        assertEq(uint(info.state), uint(Raffle.RaffleState.COMPLETED), "Raffle should be completed");
        assertEq(info.winner, alice, "Alice should be the winner");
    }

    function test_processWinnerPayouts_notFeaturedRaffle() public {
        // Create a NON-FEATURED raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5,
            false // Set featured to false
        );
        vm.stopPrank();

        // Alice buys 5 tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Bob buys 5 tickets
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Get initial balances
        uint256 aliceInitialBalance = alice.balance;
        uint256 platformInitialBalance = platform.balance;
        uint256 ownerInitialBalance = owner.balance;

        // Mock VRF callback with a random word that will select Alice as winner
        // We'll use a random word that will result in index 0-4 (Alice's tickets)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 2; // This will select index 2, which is one of Alice's tickets

        // Get the request ID from the raffle
        uint256 requestId = raffle.getRaffleInfo(0).requestId;

        // Mock the VRF callback by calling rawFulfillRandomWords directly on the Raffle contract
        vm.prank(address(vrf));
        raffle.rawFulfillRandomWords(requestId, randomWords);

        // Calculate expected payouts for a NON-FEATURED raffle
        uint256 totalPrize = 10 ether;
        uint256 platformFee = (totalPrize * 10) / 100; // 10% platform fee for non-featured
        uint256 winnerPrize = (totalPrize * 10) / 100; // 10% winner fee
        uint256 creatorPayout = totalPrize - platformFee - winnerPrize; // Remaining for creator

        // Verify balances after payouts
        assertEq(alice.balance, aliceInitialBalance + winnerPrize, "Alice should receive winner prize");
        assertEq(platform.balance, platformInitialBalance + platformFee, "Platform should receive 10% fee for non-featured raffle");
        assertEq(owner.balance, ownerInitialBalance + creatorPayout, "Owner should receive creator payout");

        // Verify NFT transfer
        assertEq(nft.ownerOf(TOKEN_ID), alice, "NFT should be transferred to winner");

        // Verify raffle state
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);
        assertEq(uint(info.state), uint(Raffle.RaffleState.COMPLETED), "Raffle should be completed");
        assertEq(info.winner, alice, "Alice should be the winner");
    }
} 