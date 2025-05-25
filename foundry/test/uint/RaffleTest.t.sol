// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
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

    // ...rest of your test functions (unchanged, but using nft and vrf as above)...
}