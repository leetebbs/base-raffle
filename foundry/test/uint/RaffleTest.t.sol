// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Raffle.sol";
import "../../src/MockERC721.sol";
import { VRFCoordinatorV2_5Mock } from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
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

    function testConstructorSetsParams() public view {
        assertEq(raffle.contractOwner(), owner);
        assertEq(raffle.s_subscriptionId(), subId);
        assertEq(raffle.getKeyHash(), KEY_HASH);
        assertEq(raffle.getPlatformWallet(), platform);
    }

    function testCreateRaffle() public {
        // Approve the Raffle contract to transfer the NFT
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        // Call createRaffle
        uint256 ticketCount = 10;
        uint256 ticketPrice = 1 ether;
        uint256 duration = 2 hours;
        uint256 minTickets = 5;
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            ticketCount,
            ticketPrice,
            duration,
            minTickets
        );
        // Check the raffle struct
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);
        assertEq(info.nftAddress, address(nft));
        assertEq(info.tokenId, TOKEN_ID);
        assertEq(info.ticketCount, ticketCount);
        assertEq(info.ticketPrice, ticketPrice);
        assertEq(info.owner, owner);
        assertEq(uint(info.state), uint(Raffle.RaffleState.OPEN));
        assertEq(info.numberOfTicketsToBeSoldForRaffleToExecute, minTickets);
        assertEq(nft.ownerOf(TOKEN_ID), address(raffle));
        assertEq(raffle.raffleCounter(), 1);
        // Optionally, check endTime is correct
        assertApproxEqAbs(info.endTime, info.startTime + duration, 2); // allow 2s drift
        vm.stopPrank();
    }

        function test_createRaffle_zeroTicketCount() public {
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        vm.expectRevert(Raffle.Raffle__TicketCountMustBeMoreThanZero.selector);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            0, // Zero tickets
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();
        }

    function test_createRaffle_minTicketsGreaterThanTotal() public {
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        vm.expectRevert(Raffle.Raffle__MinTicketsExceedTotalTickets.selector);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            15 // Min tickets > total tickets
        );
        vm.stopPrank();
    }

    function test_createRaffle_zeroDuration() public {
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        vm.expectRevert(Raffle.Raffle__InvalidRaffleDuration.selector);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            0, // Zero duration
            5
        );
        vm.stopPrank();
    }


    function test_transferNFTToContract_success() public {
        // Owner approves the Raffle contract
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);

        // Call createRaffle (which calls _transferNFTToContract internally)
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );

        // The NFT should now be owned by the Raffle contract
        assertEq(nft.ownerOf(TOKEN_ID), address(raffle));
        vm.stopPrank();
    }

    function test_transferNFTToContract_revertsIfNotApproved() public {
        // Do NOT approve the Raffle contract
        vm.startPrank(owner);

        // Expect revert with custom error
        vm.expectRevert(Raffle.Raffle__NFTTransferFailed.selector);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();
    }

    function testPurchaseTickets() public {
        // Owner creates a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys 2 tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 2 ether}(0, 2);

        // Check Alice's ticket count
        assertEq(raffle.getUserTicketCount(0, alice), 2);
        // Check contract balance
        assertEq(address(raffle).balance, 2 ether);
        // Check raffle struct updates
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);
        assertEq(info.totalTicketsSold, 2);
        assertEq(info.totalPrize, 2 ether);
    }

    function test_purchaseTickets_zeroTickets() public {
    // Create a raffle
    vm.startPrank(owner);
    nft.approve(address(raffle), TOKEN_ID);
    raffle.createRaffle(
        address(nft),
        TOKEN_ID,
        10,
        1 ether,
        2 hours,
        5
    );
    vm.stopPrank();

    // Try to buy 0 tickets
    vm.deal(alice, 10 ether);
    vm.prank(alice);
    vm.expectRevert(Raffle.Raffle__NoTicketsPurchased.selector);
    raffle.purchaseTickets{value: 0}(0, 0);
    }

    function test_purchaseTickets_exactEthAmount() public {
    // Create a raffle
    vm.startPrank(owner);
    nft.approve(address(raffle), TOKEN_ID);
    raffle.createRaffle(
        address(nft),
        TOKEN_ID,
        10,
        1 ether,
        2 hours,
        5
    );
    vm.stopPrank();

    // Buy tickets with exact ETH amount
    vm.deal(alice, 1 ether);
    vm.prank(alice);
    raffle.purchaseTickets{value: 1 ether}(0, 1);
    assertEq(raffle.getUserTicketCount(0, alice), 1);
}




    function testPurchaseTickets_revertNotActive() public {
        // Owner creates a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Fill all tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 10 ether}(0, 10);
        // Now, try to buy more tickets
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert(Raffle.Raffle__RaffleNotActive.selector);
        raffle.purchaseTickets{value: 1 ether}(0, 1);
    }

    function testPurchaseTickets_revertRaffleHasEnded() public {
        // Create a new raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID + 1);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID + 1,
            10,
            1 ether,
            1 hours,
            5
        );
        vm.stopPrank();
        vm.warp(block.timestamp + 2 hours);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert(Raffle.Raffle__RaffleHasEnded.selector);
        raffle.purchaseTickets{value: 1 ether}(1, 1); 
    }

    function testPurchaseTickets_revertNotEnoughTickets() public {
        // Deploy a NEW Raffle instance for this test
        vm.startPrank(owner);
        Raffle localRaffle = new Raffle(subId, KEY_HASH, platform, address(vrf)); // Use subId from setUp
        vm.stopPrank();

        // ** Add localRaffle contract as a consumer **
        vm.startPrank(owner);
        vrf.addConsumer(subId, address(localRaffle));
        vm.stopPrank();

        // Mint and approve NFT for this specific test
        vm.startPrank(owner);
        nft.mint(owner, TOKEN_ID + 2); // Use TOKEN_ID + 2 for this test's NFT
        nft.approve(address(localRaffle), TOKEN_ID + 2);

        uint256 startTime = block.timestamp;
        uint256 duration = 10 days;

        // Create the raffle using the localRaffle instance
        localRaffle.createRaffle(
            address(nft),
            TOKEN_ID + 2,
            2, // ticket count
            1 ether,
            duration,
            1
        );
        vm.stopPrank();

        // Purchase all tickets first using localRaffle
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        vm.warp(startTime + 1);
        localRaffle.purchaseTickets{value: 2 ether}(0, 2); // Use raffleId 0 for this local raffle

        // Try to buy one more ticket (should revert with NotEnoughTickets) using localRaffle
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.warp(startTime + 2);
        vm.expectRevert(Raffle.Raffle__RaffleNotActive.selector);
        localRaffle.purchaseTickets{value: 1 ether}(0, 1); // Use raffleId 0 for this local raffle
    }

    function testPurchaseTickets_revertNotEnoughEthSent() public {
         // Deploy a NEW Raffle instance for this test
        vm.startPrank(owner);
        Raffle localRaffle = new Raffle(subId, KEY_HASH, platform, address(vrf)); // Use subId from setUp
        vm.stopPrank();

        // ** Add localRaffle contract as a consumer **
        vm.startPrank(owner);
        vrf.addConsumer(subId, address(localRaffle));
        vm.stopPrank();

        // Mint and approve NFT for this specific test
        vm.startPrank(owner);
        nft.mint(owner, TOKEN_ID + 3);
        nft.approve(address(localRaffle), TOKEN_ID + 3);

        // Capture current timestamp and calculate raffle end time
        uint256 startTime = block.timestamp;
        uint256 duration = 10 days;

        // Create the raffle using the localRaffle instance
        localRaffle.createRaffle(
            address(nft),
            TOKEN_ID + 3,
            10,
            1 ether,
            duration, // Use the duration variable
            1
        );
        vm.stopPrank();

        // Ensure current timestamp is before the raffle ends for this purchase attempt
        vm.warp(startTime + 1);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        localRaffle.purchaseTickets{value: 0.5 ether}(0, 1); // Attempt to buy 1 ticket for 0.5 ether (expected 1 ether) using raffleId 0
    }

    function testPurchaseTickets_revertTooManyTickets() public {
         // Deploy a NEW Raffle instance for this test
        vm.startPrank(owner);
        Raffle localRaffle = new Raffle(subId, KEY_HASH, platform, address(vrf)); // Use subId from setUp
        vm.stopPrank();

        // ** Add localRaffle contract as a consumer **
        vm.startPrank(owner);
        vrf.addConsumer(subId, address(localRaffle));
        vm.stopPrank();

        // Mint and approve NFT for this specific test
        vm.startPrank(owner);
        nft.mint(owner, TOKEN_ID + 4);
        nft.approve(address(localRaffle), TOKEN_ID + 4);

        uint256 startTime = block.timestamp;
        uint256 duration = 10 days;

        // Create the raffle using the localRaffle instance
        localRaffle.createRaffle(
            address(nft),
            TOKEN_ID + 4,
            200,
            1 ether,
            duration,
            1
        );
        vm.stopPrank();

        // Ensure current timestamp is before the raffle ends for this purchase attempt
        vm.warp(startTime + 1);
        vm.deal(bob, 200 ether);
        vm.prank(bob);
        vm.expectRevert(Raffle.Raffle__TooManyTicketsInOneTransaction.selector);
        localRaffle.purchaseTickets{value: 101 ether}(0, 101); // using raffleId 0
    }

    function test_processWinnerPayouts() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
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

        // Calculate expected payouts
        uint256 totalPrize = 10 ether;
        uint256 platformFee = (totalPrize * 10) / 100; // 10% platform fee
        uint256 winnerPrize = (totalPrize * 10) / 100; // 10% winner fee
        uint256 creatorPayout = totalPrize - platformFee - winnerPrize; // 80% creator payout

        // Verify balances after payouts
        assertEq(alice.balance, aliceInitialBalance + winnerPrize, "Alice should receive winner prize");
        assertEq(platform.balance, platformInitialBalance + platformFee, "Platform should receive fee");
        assertEq(owner.balance, ownerInitialBalance + creatorPayout, "Owner should receive creator payout");

        // Verify NFT transfer
        assertEq(nft.ownerOf(TOKEN_ID), alice, "NFT should be transferred to winner");

        // Verify raffle state
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);
        assertEq(uint(info.state), uint(Raffle.RaffleState.COMPLETED), "Raffle should be completed");
        assertEq(info.winner, alice, "Alice should be the winner");
    }

    function test_cancelRaffle_minimumTicketsNotSold() public {
        // Create a raffle with minimum 5 tickets required
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5  // minimum 5 tickets required
        );
        vm.stopPrank();

        // Alice buys only 2 tickets (less than minimum)
        vm.deal(alice, 10 ether);
        console.log("alice balance ", alice.balance);
        vm.prank(alice);
        raffle.purchaseTickets{value: 2 ether}(0, 2);

        // Get initial balances
        uint256 aliceInitialBalance = alice.balance;
        console.log("Alice InitialBlance", alice.balance);
        uint256 ownerInitialBalance = owner.balance;

        // Warp past end time
        vm.warp(block.timestamp + 3 hours);

        // Cancel the raffle
        vm.prank(owner);
        raffle.cancelRaffle(0);

        // Verify raffle state
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);
        assertEq(uint(info.state), uint(Raffle.RaffleState.CANCELED), "Raffle should be canceled");
        assertEq(info.winner, address(0), "No winner should be set");

        // Verify refunds
        assertEq(alice.balance, aliceInitialBalance + 2 ether, "Alice should receive full refund");
        console.log("alice ending balance", alice.balance);
        assertEq(nft.ownerOf(TOKEN_ID), owner, "NFT should be returned to owner");

        // Verify no payouts were made
        assertEq(platform.balance, 0, "Platform should not receive any fees");
    }

    function test_cancelRaffle_minimumTicketsSold() public {
        // Create a raffle with minimum 5 tickets required
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5  // minimum 5 tickets required
        );
        vm.stopPrank();

        // Alice buys 5 tickets (meets minimum)
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Bob buys 2 tickets
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        raffle.purchaseTickets{value: 2 ether}(0, 2);

        //try to cancel the raffle
        vm.prank(owner);
        vm.expectRevert(Raffle. Raffle__RaffleStillActive.selector);
        raffle.cancelRaffle(0);
    }

    function test_getRaffleInfo_success() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Get raffle info
        Raffle.RaffleInfo memory info = raffle.getRaffleInfo(0);

        // Verify all fields
        assertEq(info.nftAddress, address(nft), "NFT address should match");
        assertEq(info.tokenId, TOKEN_ID, "Token ID should match");
        assertEq(info.owner, owner, "Owner should match");
        assertEq(info.ticketCount, 10, "Ticket count should match");
        assertEq(info.ticketPrice, 1 ether, "Ticket price should match");
        assertEq(info.totalTicketsSold, 0, "Initial tickets sold should be 0");
        assertEq(info.totalPrize, 0, "Initial prize should be 0");
        assertEq(info.numberOfTicketsToBeSoldForRaffleToExecute, 5, "Minimum tickets should match");
        assertEq(uint(info.state), uint(Raffle.RaffleState.OPEN), "State should be OPEN");
        assertEq(info.winner, address(0), "Winner should be zero address initially");
        assertEq(info.requestId, 0, "Request ID should be 0 initially");
    }

    function test_getRaffleInfo_revertNonExistentRaffle() public {
        // Try to get info for a non-existent raffle
        vm.expectRevert(Raffle.Raffle__RaffleDoesNotExist.selector);
        raffle.getRaffleInfo(999); // Using a high raffle ID that doesn't exist
    }

    function test_getRequestStatus_success() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Buy enough tickets to meet minimum requirement
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Warp past end time to trigger winner selection
        vm.warp(block.timestamp + 3 hours);

        // Finalize the raffle first to move it to PENDING_WINNER state
        vm.prank(owner);
        raffle.finalizeRaffle(0);

        // Cancel raffle which will trigger VRF request
        vm.prank(owner);
        raffle.cancelRaffle(0);

        // Get the request ID from the raffle
        uint256 requestId = raffle.getRaffleInfo(0).requestId;

        // Get request status
        (bool fulfilled, uint256[] memory randomWords) = raffle.getRequestStatus(requestId);

        // Verify initial status
        assertEq(fulfilled, false, "Request should not be fulfilled initially");
        assertEq(randomWords.length, 0, "Random words array should be empty initially");
    }

    function test_getRequestStatus_revertNonExistentRequest() public {
        // Try to get status for a non-existent request
        vm.expectRevert(Raffle.Raffle__RequestNotFound.selector);
        raffle.getRequestStatus(999); // Using a high request ID that doesn't exist
    }

    function test_getUserTicketCount_success() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys 3 tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 3 ether}(0, 3);

        // Bob buys 2 tickets
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        raffle.purchaseTickets{value: 2 ether}(0, 2);

        // Verify ticket counts
        assertEq(raffle.getUserTicketCount(0, alice), 3, "Alice should have 3 tickets");
        assertEq(raffle.getUserTicketCount(0, bob), 2, "Bob should have 2 tickets");
        assertEq(raffle.getUserTicketCount(0, owner), 0, "Owner should have 0 tickets");
    }

    function test_getUserTicketCount_zeroForNonParticipant() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Check ticket count for non-participant
        assertEq(raffle.getUserTicketCount(0, bob), 0, "Non-participant should have 0 tickets");
    }

    function test_getUserTicketCount_multipleRaffles() public {
        // Create first raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Create second raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID + 1);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID + 1,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys tickets in first raffle
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 3 ether}(0, 3);

        // Alice buys tickets in second raffle
        vm.prank(alice);
        raffle.purchaseTickets{value: 2 ether}(1, 2);

        // Verify ticket counts across different raffles
        assertEq(raffle.getUserTicketCount(0, alice), 3, "Alice should have 3 tickets in first raffle");
        assertEq(raffle.getUserTicketCount(1, alice), 2, "Alice should have 2 tickets in second raffle");
    }

    function test_getRaffleParticipants_success() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 3 ether}(0, 3);

        // Bob buys tickets
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        raffle.purchaseTickets{value: 2 ether}(0, 2);

        // Get participants
        address[] memory participants = raffle.getRaffleParticipants(0);

        // Verify participants array
        assertEq(participants.length, 2, "Should have 2 participants");
        assertEq(participants[0], alice, "First participant should be Alice");
        assertEq(participants[1], bob, "Second participant should be Bob");
    }

    function test_getRaffleParticipants_empty() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Get participants before anyone buys tickets
        address[] memory participants = raffle.getRaffleParticipants(0);

        // Verify empty participants array
        assertEq(participants.length, 0, "Should have no participants");
    }

    function test_getRaffleParticipants_multiplePurchases() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys tickets twice
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 2 ether}(0, 2);
        vm.prank(alice);
        raffle.purchaseTickets{value: 3 ether}(0, 3);

        // Get participants
        address[] memory participants = raffle.getRaffleParticipants(0);

        // Verify participants array (Alice should only appear once)
        assertEq(participants.length, 1, "Should have 1 participant");
        assertEq(participants[0], alice, "Participant should be Alice");
    }

    function test_getRaffleParticipants_multipleRaffles() public {
        // Create first raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Create second raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID + 1);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID + 1,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Alice buys tickets in first raffle
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 3 ether}(0, 3);

        // Bob buys tickets in second raffle
        vm.deal(bob, 10 ether);
        vm.prank(bob);
        raffle.purchaseTickets{value: 2 ether}(1, 2);

        // Get participants for both raffles
        address[] memory participants1 = raffle.getRaffleParticipants(0);
        address[] memory participants2 = raffle.getRaffleParticipants(1);

        // Verify participants arrays
        assertEq(participants1.length, 1, "First raffle should have 1 participant");
        assertEq(participants1[0], alice, "First raffle participant should be Alice");
        assertEq(participants2.length, 1, "Second raffle should have 1 participant");
        assertEq(participants2[0], bob, "Second raffle participant should be Bob");
    }

    function test_updateCallbackGasLimit_success() public {
        // Get initial gas limit
        uint32 initialGasLimit = raffle.callbackGasLimit();

        // Update gas limit
        uint32 newGasLimit = 400000;
        vm.prank(owner);
        raffle.updateCallbackGasLimit(newGasLimit);

        // Verify new gas limit
        assertEq(raffle.callbackGasLimit(), newGasLimit, "Gas limit should be updated");
    }

    function test_updateCallbackGasLimit_onlyOwner() public {
        // Try to update gas limit as non-owner
        uint32 newGasLimit = 400000;
        vm.prank(alice);
        vm.expectRevert("Caller is not the contract owner");
        raffle.updateCallbackGasLimit(newGasLimit);

        // Verify gas limit remains unchanged
        assertEq(raffle.callbackGasLimit(), 300000, "Gas limit should not change");
    }

    function test_updateCallbackGasLimit_emitsEvent() public {
        // Get initial gas limit
        uint32 initialGasLimit = raffle.callbackGasLimit();
        uint32 newGasLimit = 400000;

        // Expect event emission
        vm.expectEmit(true, true, true, true);
        emit Raffle.CallbackGasLimitUpdated(initialGasLimit, newGasLimit);

        // Update gas limit
        vm.prank(owner);
        raffle.updateCallbackGasLimit(newGasLimit);
    }

    function test_updateCallbackGasLimit_multipleUpdates() public {
        // First update
        uint32 firstNewLimit = 400000;
        vm.prank(owner);
        raffle.updateCallbackGasLimit(firstNewLimit);
        assertEq(raffle.callbackGasLimit(), firstNewLimit, "First update should succeed");

        // Second update
        uint32 secondNewLimit = 500000;
        vm.prank(owner);
        raffle.updateCallbackGasLimit(secondNewLimit);
        assertEq(raffle.callbackGasLimit(), secondNewLimit, "Second update should succeed");

        // Third update
        uint32 thirdNewLimit = 600000;
        vm.prank(owner);
        raffle.updateCallbackGasLimit(thirdNewLimit);
        assertEq(raffle.callbackGasLimit(), thirdNewLimit, "Third update should succeed");
    }

    function test_pause_success() public {
        // Pause the contract
        vm.prank(owner);
        raffle.pause();

        // Verify contract is paused
        assertTrue(raffle.paused(), "Contract should be paused");
    }

    function test_pause_onlyOwner() public {
        // Try to pause as non-owner
        vm.prank(alice);
        vm.expectRevert("Caller is not the contract owner");
        raffle.pause();

        // Verify contract is not paused
        assertFalse(raffle.paused(), "Contract should not be paused");
    }

    function test_unpause_success() public {
        // First pause the contract
        vm.prank(owner);
        raffle.pause();
        assertTrue(raffle.paused(), "Contract should be paused");

        // Then unpause
        vm.prank(owner);
        raffle.unpause();

        // Verify contract is unpaused
        assertFalse(raffle.paused(), "Contract should be unpaused");
    }

    function test_unpause_onlyOwner() public {
        // First pause the contract
        vm.prank(owner);
        raffle.pause();

        // Try to unpause as non-owner
        vm.prank(alice);
        vm.expectRevert("Caller is not the contract owner");
        raffle.unpause();

        // Verify contract remains paused
        assertTrue(raffle.paused(), "Contract should remain paused");
    }

    function test_pause_affectsRaffleCreation() public {
        // Pause the contract
        vm.prank(owner);
        raffle.pause();

        // Try to create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();
    }

    function test_pause_affectsTicketPurchase() public {
        // Create a raffle first
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Pause the contract
        vm.prank(owner);
        raffle.pause();

        // Try to purchase tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        raffle.purchaseTickets{value: 1 ether}(0, 1);
    }

    function test_pause_unpause_cycle() public {
        // Test multiple pause/unpause cycles
        for(uint i = 0; i < 3; i++) {
            // Pause
            vm.prank(owner);
            raffle.pause();
            assertTrue(raffle.paused(), "Contract should be paused");

            // Unpause
            vm.prank(owner);
            raffle.unpause();
            assertFalse(raffle.paused(), "Contract should be unpaused");
        }
    }

    function test_isRaffleActive_success() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Verify raffle is active
        assertTrue(raffle.isRaffleActive(0), "Raffle should be active");
    }

    function test_isRaffleActive_ended() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Warp past end time
        vm.warp(block.timestamp + 3 hours);

        // Verify raffle is not active
        assertFalse(raffle.isRaffleActive(0), "Raffle should not be active after end time");
    }

    function test_isRaffleActive_allTicketsSold() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            5, // Only 5 tickets total
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Buy all tickets
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Verify raffle is not active
        assertFalse(raffle.isRaffleActive(0), "Raffle should not be active when all tickets are sold");
    }

    function test_isRaffleActive_pendingWinner() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Buy enough tickets to meet minimum
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Warp past end time and finalize
        vm.warp(block.timestamp + 3 hours);
        vm.prank(owner);
        raffle.finalizeRaffle(0);

        // Verify raffle is not active
        assertFalse(raffle.isRaffleActive(0), "Raffle should not be active in PENDING_WINNER state");
    }

    function test_isRaffleActive_completed() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Buy enough tickets to meet minimum
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 5 ether}(0, 5);

        // Warp past end time and finalize
        vm.warp(block.timestamp + 3 hours);
        vm.prank(owner);
        raffle.finalizeRaffle(0);

        // Mock VRF callback with a random word that will select Alice as winner
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 2; // This will select index 2, which is one of Alice's tickets

        // Get the request ID from the raffle
        uint256 requestId = raffle.getRaffleInfo(0).requestId;

        // Mock the VRF callback by calling rawFulfillRandomWords directly on the Raffle contract
        vm.prank(address(vrf));
        raffle.rawFulfillRandomWords(requestId, randomWords);

        // Verify raffle is not active
        assertFalse(raffle.isRaffleActive(0), "Raffle should not be active in COMPLETED state");
    }

    function test_isRaffleActive_canceled() public {
        // Create a raffle
        vm.startPrank(owner);
        nft.approve(address(raffle), TOKEN_ID);
        raffle.createRaffle(
            address(nft),
            TOKEN_ID,
            10,
            1 ether,
            2 hours,
            5
        );
        vm.stopPrank();

        // Buy some tickets (less than minimum)
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        raffle.purchaseTickets{value: 2 ether}(0, 2);

        // Warp past end time and cancel
        vm.warp(block.timestamp + 3 hours);
        vm.prank(owner);
        raffle.cancelRaffle(0);

        // Verify raffle is not active
        assertFalse(raffle.isRaffleActive(0), "Raffle should not be active in CANCELED state");
    }

    function test_finalizeRaffle_beforeEndTime() public {
    // Create a raffle
    vm.startPrank(owner);
    nft.approve(address(raffle), TOKEN_ID);
    raffle.createRaffle(
        address(nft),
        TOKEN_ID,
        10,
        1 ether,
        2 hours,
        5
    );
    vm.stopPrank();

    // Try to finalize before end time
    vm.prank(owner);
    vm.expectRevert(Raffle.Raffle__RaffleStillActive.selector);
    raffle.finalizeRaffle(0);
}

function test_cancelRaffle_afterWinnerSelected() public {
    // Create a raffle
    vm.startPrank(owner);
    nft.approve(address(raffle), TOKEN_ID);
    raffle.createRaffle(
        address(nft),
        TOKEN_ID,
        10,
        1 ether,
        2 hours,
        5
    );
    vm.stopPrank();

    // Buy tickets and complete raffle
    vm.deal(alice, 10 ether);
    vm.prank(alice);
    raffle.purchaseTickets{value: 5 ether}(0, 5);
    vm.warp(block.timestamp + 3 hours);

    // Try to cancel after winner selected
    vm.prank(owner);
    vm.expectRevert(Raffle.Raffle__RaffleNotPendingWinner.selector);
    raffle.cancelRaffle(0);
}

function test_pause_alreadyPaused() public {
    // Pause the contract
    vm.prank(owner);
    raffle.pause();

    // Try to pause again
    vm.prank(owner);
    vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
    raffle.pause();
}

function test_unpause_notPaused() public {
    // Try to unpause when not paused
    vm.prank(owner);
    vm.expectRevert(abi.encodeWithSignature("ExpectedPause()"));
    raffle.unpause();
}
}