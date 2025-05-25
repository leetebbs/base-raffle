// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockERC721} from "../../src/MockERC721.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    // Events from Raffle contract to test against
    event TicketPurchased(uint256 indexed raffleId, address indexed buyer, uint256 numberOfTickets);
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 ticketCount,
        uint256 raffleLengthInSeconds,
        uint256 minimumTicketsToBeSoldForRaffleToExecute,
        uint256 ticketPrice
    );
    event WinnerSelected(uint256 indexed raffleId, address indexed winner);
    event RandomWordsRequested(uint256 indexed raffleId, uint256 indexed requestId);

    // Constants for testing
    uint256 public constant STARTING_USER_BALANCE = 100 ether;
    bytes32 public constant KEY_HASH = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint256 public SUBSCRIPTION_ID; 
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    
    // Test NFT constants
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant TICKET_COUNT = 100;
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant RAFFLE_LENGTH_IN_SECONDS = 86400; // 1 day
    uint256 public constant MIN_TICKETS_TO_BE_SOLD = 10;
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 10; // 10% platform fee
    
    // Contract instances
    Raffle public raffleContract;  
    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;
    MockERC721 public mockNft;
    
    // Test addresses
    address public owner = makeAddr("owner");
    address public buyer1 = makeAddr("buyer1");
    address public buyer2 = makeAddr("buyer2");
    address public buyer3 = makeAddr("buyer3");
    address public platformWallet = makeAddr("platformWallet");
    
    // Test state variables
    uint256 public raffleId;
    
    function setUp() public {
        // Set up test balances
        vm.deal(owner, STARTING_USER_BALANCE);
        vm.deal(buyer1, STARTING_USER_BALANCE);
        vm.deal(buyer2, STARTING_USER_BALANCE);
        vm.deal(buyer3, STARTING_USER_BALANCE);
        
        // Deploy contracts
        vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(1 ether, 1e9, 1e2);
        
        // Create subscription and store the ID
        SUBSCRIPTION_ID = uint256(vrfCoordinatorMock.createSubscription());
        console.log("Subscription ID: %s", SUBSCRIPTION_ID);
        vrfCoordinatorMock.fundSubscription(SUBSCRIPTION_ID, 10 ether);
        
        // Deploy the raffle contract AS THE OWNER address
        vm.startPrank(owner); // Add this line - critical!
        raffleContract = new Raffle(
            address(vrfCoordinatorMock),
            KEY_HASH,
            SUBSCRIPTION_ID,
            platformWallet
        );
        vm.stopPrank(); // Add this line
    
        // Add consumer to the subscription
        vrfCoordinatorMock.addConsumer(SUBSCRIPTION_ID, address(raffleContract));
        
        // Deploy mock NFT
        mockNft = new MockERC721("TestNFT", "TNFT");
        
        // Mint NFT to owner
        vm.startPrank(owner);
        mockNft.mint(owner, TOKEN_ID);
        vm.stopPrank();
    }
    
    function test_CreateRaffle() public {
        // Arrange
        vm.startPrank(owner);
        mockNft.approve(address(raffleContract), TOKEN_ID);
        
        // Act & Assert
        vm.expectEmit(true, true, true, true);
        emit RaffleCreated(
            0,
            owner,
            address(mockNft),
            TOKEN_ID,
            TICKET_COUNT,
            RAFFLE_LENGTH_IN_SECONDS,
            MIN_TICKETS_TO_BE_SOLD,
            TICKET_PRICE
        );
        
        raffleContract.createRaffle(
            address(mockNft),
            TOKEN_ID,
            TICKET_COUNT,
            TICKET_PRICE,
            RAFFLE_LENGTH_IN_SECONDS,
            MIN_TICKETS_TO_BE_SOLD
        );
        vm.stopPrank();
        
        // Assert
        assertEq(raffleContract.raffleCounter(), 1);
        assertEq(mockNft.ownerOf(TOKEN_ID), address(raffleContract));
        
        // Get the raffle info and check all values
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertEq(raffle.nftAddress, address(mockNft));
        assertEq(raffle.tokenId, TOKEN_ID);
        assertEq(raffle.owner, owner);
        assertEq(raffle.ticketCount, TICKET_COUNT);
        assertEq(raffle.ticketPrice, TICKET_PRICE);
        assertEq(raffle.endTime, block.timestamp + RAFFLE_LENGTH_IN_SECONDS);
        assertEq(raffle.totalTicketsSold, 0);
        assertEq(raffle.totalPrize, 0);
        assertEq(raffle.numberOfTicketsToBeSoldForRaffleToExecute, MIN_TICKETS_TO_BE_SOLD);
        assertTrue(raffle.active);
    }
    
    function test_PurchaseTickets() public {
        // Arrange
        _createRaffle();
        uint256 numTickets = 5;
        
        // Act
        vm.startPrank(buyer1);
        vm.expectEmit(true, true, false, true);
        emit TicketPurchased(0, buyer1, numTickets);
        raffleContract.purchaseATicketForARaffle{value: numTickets * TICKET_PRICE}(0, numTickets);
        vm.stopPrank();
        
        // Assert
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertEq(raffle.totalTicketsSold, numTickets);
        assertEq(raffle.totalPrize, numTickets * TICKET_PRICE);
        assertEq(raffleContract.getRaffleTicketHoldersCount(0), numTickets);
        
        // Check the ticket holders array
        address[] memory ticketHolders = raffleContract.getRaffleTicketHolders(0);
        for (uint256 i = 0; i < numTickets; i++) {
            assertEq(ticketHolders[i], buyer1);
        }
    }
    
    function test_PurchaseTicketsMultipleBuyers() public {
        // Arrange
        _createRaffle();
        
        // Act - Buyer 1 purchases tickets
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: 3 * TICKET_PRICE}(0, 3);
        vm.stopPrank();
        
        // Buyer 2 purchases tickets
        vm.startPrank(buyer2);
        raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
        vm.stopPrank();
        
        // Buyer 3 purchases tickets
        vm.startPrank(buyer3);
        raffleContract.purchaseATicketForARaffle{value: 2 * TICKET_PRICE}(0, 2);
        vm.stopPrank();
        
        // Assert
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertEq(raffle.totalTicketsSold, 10);
        assertEq(raffle.totalPrize, 10 * TICKET_PRICE);
        assertEq(raffleContract.getRaffleTicketHoldersCount(0), 10);
        
        // Since we sold exactly MIN_TICKETS_TO_BE_SOLD, the raffle should be closed
        assertFalse(raffle.active);
    }
    
    function test_RaffleEndsWhenAllTicketsSold() public {
        // Arrange - create raffle with lower ticket count to simplify test
        _createRaffleWithCustomParameters(5, 0.1 ether, 86400, 1);
        
        // Act - Sell all tickets
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
        vm.stopPrank();
        
        // Assert
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertEq(raffle.totalTicketsSold, 5);
        assertFalse(raffle.active); // Raffle should be inactive when all tickets are sold
    }
    
    function test_RaffleEndsWhenTimeExpires() public {
        // Arrange
        _createRaffle();
        
        // Act - Advance time beyond end time
        uint256 newTimestamp = block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1;
        vm.warp(newTimestamp);
        
        // Assert - Check that the current time is past the raffle end time
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertTrue(block.timestamp > raffle.endTime, "Current time should be past raffle end time");
        
        // Additional verification: attempting to purchase tickets should fail
        vm.startPrank(buyer1);
        vm.expectRevert("Raffle__RaffleHasEnded()"); // Add specific error message
        raffleContract.purchaseATicketForARaffle{value: TICKET_PRICE}(0, 1);
        vm.stopPrank();
    }
    
    function test_RaffleEndsWhenMinimumTicketsSold() public {
        // Arrange
        _createRaffle();
        
        // Act - Sell exactly the minimum number of tickets
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
        vm.stopPrank();
        
        // Assert
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertFalse(raffle.active); // Raffle should be inactive when minimum tickets are sold
    }
    
        function test_WinnerPickingWhenAllTicketsSold() public {
        // Arrange - create raffle with lower ticket count
        _createRaffleWithCustomParameters(5, 0.1 ether, 86400, 3);
        
        // Record logs to check for events
        vm.recordLogs();
        
        // Act - Sell all tickets
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
        vm.stopPrank();
        
        // Get logs and check for RandomWordsRequested event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool randomWordsRequested = false;
        uint256 requestId;
        
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
                randomWordsRequested = true;
                requestId = uint256(entries[i].topics[2]);
                break;
            }
        }
        
        // Assert raffle is inactive and random words were requested
        Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
        assertFalse(raffle.active, "Raffle should be inactive");
        assertTrue(randomWordsRequested, "RandomWordsRequested event should be emitted");
        
        // Fulfill random words to complete the process
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123;
        
        vm.startPrank(address(vrfCoordinatorMock));
        raffleContract.rawFulfillRandomWords(requestId, randomWords);
        vm.stopPrank();
        
        // Verify winner was selected
        raffle = raffleContract.getRaffleInfo(0);
        assertNotEq(raffle.winner, address(0), "Winner should be set");
    }

//         function test_WinnerPickingWhenTimeExpires() public {
//     // Arrange - create a raffle with sufficient tickets
//     _createRaffle();
    
//     // Buy some tickets, but not enough to end the raffle
//     vm.startPrank(buyer1);
//     raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
//     vm.stopPrank();
    
//     // Record balances before time expiry
//     uint256 ownerBalanceBefore = owner.balance;
//     uint256 platformBalanceBefore = platformWallet.balance;
    
//     // Record logs to check for events
//     vm.recordLogs();
    
//     // Fast forward beyond raffle end time
//     vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
    
//     // Manually call pickARaffleWinner as the owner (since the raffle is now inactive)
//     vm.startPrank(owner);
//     raffleContract.pickARaffleWinner(0);
//     vm.stopPrank();
//     test_WinnerPickingWhenTimeExpires
//     // Get logs and check for RandomWordsRequested event
//     Vm.Log[] memory entries = vm.getRecordedLogs();
//     bool randomWordsRequested = false;
//     uint256 requestId;
    
//     for (uint256 i = 0; i < entries.length; i++) {
//         if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
//             randomWordsRequested = true;
//             requestId = uint256(entries[i].topics[2]);
//             break;
//         }
//     }
    
//     // Assert raffle is inactive and random words were requested
//     Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
//     assertFalse(raffle.active, "Raffle should be inactive when time expires");
//     assertTrue(randomWordsRequested, "RandomWordsRequested event should be emitted when time expires");
    
//     // Fulfill random words to complete the process
//     uint256[] memory randomWords = new uint256[](1);
//     randomWords[0] = 789; // Different number for variety in tests
    
//     vm.startPrank(address(vrfCoordinatorMock));
//     raffleContract.rawFulfillRandomWords(requestId, randomWords);
//     vm.stopPrank();
    
//     // Verify winner was selected
//     raffle = raffleContract.getRaffleInfo(0);
//     assertNotEq(raffle.winner, address(0), "Winner should be set when raffle ends by time expiry");
    
//     // Calculate and verify fee distribution
//     uint256 totalPrize = 5 * TICKET_PRICE;
//     uint256 expectedPlatformFee = (totalPrize * PLATFORM_FEE_PERCENTAGE) / 100;
//     uint256 expectedPrizeAfterFee = totalPrize - expectedPlatformFee;
    
//     assertEq(owner.balance, ownerBalanceBefore + expectedPrizeAfterFee, "Owner did not receive correct prize amount");
//     assertEq(platformWallet.balance, platformBalanceBefore + expectedPlatformFee, "Platform wallet did not receive correct fee");
// }
    
    function test_PickWinnerAndFulfillRandomness() public {
        // Arrange
        _createRaffle();
        
        // Purchase tickets
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: 3 * TICKET_PRICE}(0, 3);
        vm.stopPrank();
        
        vm.startPrank(buyer2);
        raffleContract.purchaseATicketForARaffle{value: 4 * TICKET_PRICE}(0, 4);
        vm.stopPrank();
        
        vm.startPrank(buyer3);
        raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
        vm.stopPrank();
        
        // Fast forward to end the raffle
        vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
        
        // Record balances before picking a winner
        uint256 ownerBalanceBefore = owner.balance;
        uint256 platformBalanceBefore = platformWallet.balance;
        uint256 totalPrize = 12 * TICKET_PRICE; // 12 tickets purchased
        
        // Act - Pick a winner
        vm.recordLogs();
        vm.startPrank(owner); // Add this line to ensure call is made by owner
        raffleContract.pickARaffleWinner(0);
        vm.stopPrank(); // Add this line
        
        // Get the requestId from the emitted event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId;
        
        // Find the RandomWordsRequested event and extract the requestId
        for (uint256 i = 0; i < entries.length; i++) {
            // Checking event signature for RandomWordsRequested
            if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
                requestId = entries[i].topics[2]; // Get the requestId from the indexed parameter
                break;
            }
        }
        
        // Convert bytes32 to uint256
        uint256 requestIdUint = uint256(requestId);
        
        // Generate a random number (for demonstration purposes)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456; // Using a fixed number for deterministic testing
        
        // Fulfill the random words request
        vm.recordLogs();
        // Prank as the VRF Coordinator
        vm.startPrank(address(vrfCoordinatorMock));
        raffleContract.rawFulfillRandomWords(requestIdUint, randomWords);
        vm.stopPrank();
        
        // Assert that WinnerSelected event was emitted
        entries = vm.getRecordedLogs();
        bool winnerEventFound = false;
        address winner;
        
        for (uint256 i = 0; i < entries.length; i++) {
            // Check if the event signature matches WinnerSelected
            if (entries[i].topics[0] == keccak256("WinnerSelected(uint256,address)")) {
                winnerEventFound = true;
                winner = address(uint160(uint256(entries[i].topics[2]))); // Extract winner address
                break;
            }
        }
        
        assertTrue(winnerEventFound, "WinnerSelected event was not emitted");
        
        // Calculate expected platform fee and prize after fee
        uint256 expectedPlatformFee = (totalPrize * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 expectedPrizeAfterFee = totalPrize - expectedPlatformFee;
        
        // Check balances to verify fee distribution
        assertEq(owner.balance, ownerBalanceBefore + expectedPrizeAfterFee, "Owner did not receive correct prize amount");
        assertEq(platformWallet.balance, platformBalanceBefore + expectedPlatformFee, "Platform wallet did not receive correct fee");
        
        // Calculate expected winner (for 12 tickets and randomWords[0] = 123456)
        address expectedWinner = raffleContract.getRaffleTicketHolders(0)[123456 % 12];
        assertEq(winner, expectedWinner);
        
        // Check NFT ownership
        assertEq(mockNft.ownerOf(TOKEN_ID), winner);
        
        // Verify winner is correctly set in the RaffleInfo struct
        Raffle.RaffleInfo memory raffleAfterWinnerSelected = raffleContract.getRaffleInfo(0);
        assertEq(raffleAfterWinnerSelected.winner, winner, "Winner not correctly set in RaffleInfo");
        
        // Verify getRaffleWinner getter returns the correct winner
        assertEq(raffleContract.getRaffleWinner(0), winner, "getRaffleWinner returns incorrect address");
        
        // Verify raffle is inactive
        assertFalse(raffleContract.getRaffleActive(0));
    }
    
    function test_RevertWhen_NotEnoughTickets() public {
        // Arrange
        _createRaffle();
        
        // Act & Assert - Try to purchase more tickets than available
        vm.startPrank(buyer1);
        vm.expectRevert(); // This should revert with Raffle__NotEnoughTickets
        raffleContract.purchaseATicketForARaffle{value: (TICKET_COUNT + 1) * TICKET_PRICE}(0, TICKET_COUNT + 1);
        vm.stopPrank();
    }
    
    function test_RevertWhen_NotEnoughEthSent() public {
        // Arrange
        _createRaffle();
        
        // Act & Assert - Try to purchase tickets with insufficient ETH
        vm.startPrank(buyer1);
        vm.expectRevert(); // This should revert with Raffle__NotEnoughEthSent
        raffleContract.purchaseATicketForARaffle{value: TICKET_PRICE - 1 wei}(0, 1);
        vm.stopPrank();
    }
    
    function test_RevertWhen_RaffleInactive() public {
        // Arrange
        _createRaffle();
        
        // Purchase all tickets to make the raffle inactive
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
        vm.stopPrank();
        
        // Act & Assert - Try to purchase tickets for inactive raffle
        vm.startPrank(buyer2);
        vm.expectRevert(); // This should revert with Raffle__RaffleNotActive
        raffleContract.purchaseATicketForARaffle{value: TICKET_PRICE}(0, 1);
        vm.stopPrank();
    }
    
    function test_RevertWhen_RaffleHasEnded() public {
        // Arrange
        _createRaffle();
        
        // Fast forward beyond raffle end time
        vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
        
        // Act & Assert - Try to purchase tickets for ended raffle
        vm.startPrank(buyer1);
        vm.expectRevert(); // This should revert with Raffle__RaffleHasEnded
        raffleContract.purchaseATicketForARaffle{value: TICKET_PRICE}(0, 1);
        vm.stopPrank();
    }
    
    function test_RevertWhen_RaffleStillActive() public {
        // Arrange
        _createRaffle();
        
        // Purchase some tickets but not enough to end the raffle
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
        vm.stopPrank();
        
        // Act & Assert - Try to pick a winner for active raffle
        vm.startPrank(owner); // Add this line
        vm.expectRevert(); // This should revert with Raffle__RaffleStillActive
        raffleContract.pickARaffleWinner(0);
        vm.stopPrank(); // Add this line
    }
    
    function test_RevertWhen_NoTicketsPurchased() public {
        // Arrange
        _createRaffle();
        
        // Fast forward beyond raffle end time to make it inactive
        vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
        
        // Act & Assert - Try to pick a winner when no tickets were purchased
        vm.startPrank(owner); // Add this line
        vm.expectRevert(); // This should revert with Raffle__NoTicketsPurchased
        raffleContract.pickARaffleWinner(0);
        vm.stopPrank(); // Add this line
    }
    
    function test_ViewFunctions() public {
        // Arrange
        _createRaffle();
        
        // Purchase some tickets
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
        vm.stopPrank();
        
        // Assert view functions
        assertEq(raffleContract.getRaffleTicketCount(0), TICKET_COUNT);
        assertEq(raffleContract.getRaffleTicketPrice(0), TICKET_PRICE);
        assertEq(raffleContract.getRaffleStartTime(0), 1); // Start time is set to 1 in the contract
        assertEq(raffleContract.getRaffleEndTime(0), 1 + RAFFLE_LENGTH_IN_SECONDS); // End time is start time + length
        assertEq(raffleContract.getRaffleTotalTicketsSold(0), 5);
        assertEq(raffleContract.getRaffleTotalPrize(0), 5 * TICKET_PRICE);
        assertEq(raffleContract.getRaffleNumberOfTicketsToBeSoldForRaffleToExecute(0), MIN_TICKETS_TO_BE_SOLD);
        assertTrue(raffleContract.getRaffleActive(0));
        assertEq(raffleContract.getRaffleOwner(0), owner);
        assertEq(raffleContract.getRaffleNftAddress(0), address(mockNft));
        assertEq(raffleContract.getRaffleTokenId(0), TOKEN_ID);
        assertEq(raffleContract.getRaffleTicketHoldersCount(0), 5);
        
        // Verify default winner is address(0)
        assertEq(raffleContract.getRaffleWinner(0), address(0), "Default winner should be address(0)");
    }

    function test_AutoPickWinnerWhenMinimumTicketsReached() public {
    // Arrange
    _createRaffle();
    
    // Record balances before picking a winner
    uint256 ownerBalanceBefore = owner.balance;
    uint256 platformBalanceBefore = platformWallet.balance;
    uint256 totalPrize = MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE;
    
    // Purchase tickets to reach minimum
    vm.recordLogs();
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
    vm.stopPrank();
    
    // 1. Verify RandomWordsRequested event was emitted (pickARaffleWinner was called)
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bool randomWordsRequestedEventFound = false;
    uint256 requestId;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
            randomWordsRequestedEventFound = true;
            requestId = uint256(entries[i].topics[2]);
            break;
        }
    }
    
    assertTrue(randomWordsRequestedEventFound, "RandomWordsRequested event not emitted - pickARaffleWinner wasn't called");
    
    // 2. Fulfill the random words request (simulate Chainlink VRF callback)
    uint256[] memory randomWords = new uint256[](1);
    randomWords[0] = 123456; // Fixed value for deterministic testing
    
    vm.recordLogs();
    vm.startPrank(address(vrfCoordinatorMock));
    raffleContract.rawFulfillRandomWords(requestId, randomWords);
    vm.stopPrank();
    
    // 3. Verify WinnerSelected event was emitted
    entries = vm.getRecordedLogs();
    bool winnerEventFound = false;
    address winner;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("WinnerSelected(uint256,address)")) {
            winnerEventFound = true;
            winner = address(uint160(uint256(entries[i].topics[2])));
            break;
        }
    }
    
    assertTrue(winnerEventFound, "WinnerSelected event was not emitted");
    
    // Calculate expected platform fee and prize after fee
    uint256 expectedPlatformFee = (totalPrize * PLATFORM_FEE_PERCENTAGE) / 100;
    uint256 expectedPrizeAfterFee = totalPrize - expectedPlatformFee;
    
    // Check balances to verify fee distribution
    assertEq(owner.balance, ownerBalanceBefore + expectedPrizeAfterFee, "Owner did not receive correct prize amount");
    assertEq(platformWallet.balance, platformBalanceBefore + expectedPlatformFee, "Platform wallet did not receive correct fee");
    
    // 4. Verify NFT was transferred to winner
    assertEq(mockNft.ownerOf(TOKEN_ID), winner, "NFT not transferred to winner");
    
    // 5. Verify winner is correctly set in the RaffleInfo struct
    Raffle.RaffleInfo memory raffleAfterWinnerSelected = raffleContract.getRaffleInfo(0);
    assertEq(raffleAfterWinnerSelected.winner, winner, "Winner not correctly set in RaffleInfo");
    
    // 6. Verify getRaffleWinner getter returns the correct winner
    assertEq(raffleContract.getRaffleWinner(0), winner, "getRaffleWinner returns incorrect address");
    
    // 7. Verify raffle is inactive
    assertFalse(raffleContract.getRaffleActive(0));
}
    
    function test_FeeCalculationAndDistribution() public {
    // Arrange - Create a raffle with a specific ticket price to test fee calculation
    uint256 testTicketPrice = 0.123 ether;
    _createRaffleWithCustomParameters(20, testTicketPrice, 86400, 5);
    
    // Purchase 5 tickets (exact minimum)
    uint256 ownerBalanceBefore = owner.balance;
    uint256 platformBalanceBefore = platformWallet.balance;
    uint256 totalPrize = 5 * testTicketPrice;
    
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: 5 * testTicketPrice}(0, 5);
    vm.stopPrank();
    
    // Get the requestId from the emitted event
    vm.recordLogs();
    // This will trigger the VRF coordinator request
    vm.startPrank(owner); // Add this line
    raffleContract.pickARaffleWinner(0);
    vm.stopPrank(); // Add this line
    
    Vm.Log[] memory entries = vm.getRecordedLogs();
    uint256 requestId;
    
    // Find the RandomWordsRequested event and extract the requestId
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
            requestId = uint256(entries[i].topics[2]);
            break;
        }
    }
    
    // Fulfill randomness
    uint256[] memory randomWords = new uint256[](1);
    randomWords[0] = 123456;
    
    vm.startPrank(address(vrfCoordinatorMock));
    raffleContract.rawFulfillRandomWords(requestId, randomWords);
    vm.stopPrank();
    
    // Calculate expected fees with precise math
    uint256 expectedPlatformFee = (totalPrize * PLATFORM_FEE_PERCENTAGE) / 100;
    uint256 expectedPrizeAfterFee = totalPrize - expectedPlatformFee;
    
    // Verify correct distribution
    assertEq(owner.balance, ownerBalanceBefore + expectedPrizeAfterFee, "Owner did not receive correct prize amount");
    assertEq(platformWallet.balance, platformBalanceBefore + expectedPlatformFee, "Platform wallet did not receive correct fee");
}
    
    ///////////////////
    // Helper functions
    ///////////////////
    
    function _createRaffle() internal {
        vm.startPrank(owner);
        mockNft.approve(address(raffleContract), TOKEN_ID);
        raffleContract.createRaffle(
            address(mockNft),
            TOKEN_ID,
            TICKET_COUNT,
            TICKET_PRICE,
            RAFFLE_LENGTH_IN_SECONDS,
            MIN_TICKETS_TO_BE_SOLD
        );
        vm.stopPrank();
    }
    
    function _createRaffleWithCustomParameters(
        uint256 ticketCount,
        uint256 ticketPrice,
        uint256 raffleLengthInSeconds,
        uint256 minTicketsToSell
    ) internal {
        vm.startPrank(owner);
        mockNft.approve(address(raffleContract), TOKEN_ID);
        raffleContract.createRaffle(
            address(mockNft),
            TOKEN_ID,
            ticketCount,
            ticketPrice,
            raffleLengthInSeconds,
            minTicketsToSell
        );
        vm.stopPrank();
    }
    
    function test_WinnerStorageAndRetrieval() public {
    // Arrange
    _createRaffle();
    
    // Purchase tickets
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
    vm.stopPrank();
    
    // Get the requestId from the emitted event
    vm.recordLogs();
    Vm.Log[] memory entries = vm.getRecordedLogs();
    uint256 requestId;
    
    // Find the RandomWordsRequested event and extract the requestId
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
            requestId = uint256(entries[i].topics[2]);
            break;
        }
    }
    
    // Generate and fulfill random words
    uint256[] memory randomWords = new uint256[](1);
    randomWords[0] = 42; // Different number for variety
    
    vm.recordLogs();
    vm.startPrank(address(vrfCoordinatorMock));
    raffleContract.rawFulfillRandomWords(requestId, randomWords);
    vm.stopPrank();
    
    // Extract winner from event
    entries = vm.getRecordedLogs();
    address eventWinner;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("WinnerSelected(uint256,address)")) {
            eventWinner = address(uint160(uint256(entries[i].topics[2])));
            break;
        }
    }
    
    // Assert winner is stored correctly in contract state
    assertEq(raffleContract.getRaffleWinner(0), eventWinner, "Winner from getter doesn't match event");
    
    // Get the full raffle info and check winner field
    Raffle.RaffleInfo memory raffle = raffleContract.getRaffleInfo(0);
    assertEq(raffle.winner, eventWinner, "Winner in RaffleInfo doesn't match event");
    
    // Verify consistency between getter and struct field
    assertEq(raffle.winner, raffleContract.getRaffleWinner(0), "Getter and struct field should match");
}
    
    function test_RevertWhen_NotOwnerCallsPickWinner() public {
        // Arrange
        _createRaffle();
        
        // Purchase tickets and end the raffle
        vm.startPrank(buyer1);
        raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
        vm.stopPrank();
        
        // Fast forward beyond raffle end time to ensure it's inactive
        vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
        
        // Act & Assert - Try to pick a winner as a non-owner address
        vm.startPrank(buyer1);
        vm.expectRevert(); // Should revert with Raffle__NotContractOwner
        raffleContract.pickARaffleWinner(0);
        vm.stopPrank();
    }
    
    // Tests for Chainlink Automation functionality

function test_CheckUpkeep_NoActiveRaffles() public {
    // Arrange - no raffles created yet
    
    // Act
    (bool upkeepNeeded, ) = raffleContract.checkUpkeep("");
    
    // Assert
    assertFalse(upkeepNeeded, "Should not need upkeep with no raffles");
}

function test_CheckUpkeep_ActiveRaffleNoConditionsMet() public {
    // Create a raffle but don't meet any ending conditions
    _createRaffle();
    
    // Act - check if upkeep is needed
    (bool upkeepNeeded, ) = raffleContract.checkUpkeep("");
    
    // Assert
    assertFalse(upkeepNeeded, "Should not need upkeep when no ending conditions are met");
}

function test_CheckUpkeep_MinimumTicketsReached() public {
    // Create a raffle
    _createRaffle();
    
    // Buy enough tickets to reach minimum
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
    vm.stopPrank();
    
    // Act - check if upkeep is needed
    (bool upkeepNeeded, bytes memory performData) = raffleContract.checkUpkeep("");
    
    // Assert
    assertTrue(upkeepNeeded, "Should need upkeep when minimum tickets are sold");
    
    // Decode the performData to verify it contains the correct raffle ID
    uint256[] memory raffleIds = abi.decode(performData, (uint256[]));
    assertEq(raffleIds.length, 1, "Should have 1 raffle needing upkeep");
    assertEq(raffleIds[0], 0, "Should be raffle with ID 0");
}

function test_CheckUpkeep_AllTicketsSold() public {
    // Create a raffle with low ticket count
    _createRaffleWithCustomParameters(5, 0.1 ether, 86400, 3);
    
    // Buy all tickets
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: 5 * 0.1 ether}(0, 5);
    vm.stopPrank();
    
    // Act - check if upkeep is needed
    (bool upkeepNeeded, bytes memory performData) = raffleContract.checkUpkeep("");
    
    // Assert
    assertTrue(upkeepNeeded, "Should need upkeep when all tickets are sold");
    
    // Decode the performData
    uint256[] memory raffleIds = abi.decode(performData, (uint256[]));
    assertEq(raffleIds.length, 1, "Should have 1 raffle needing upkeep");
    assertEq(raffleIds[0], 0, "Should be raffle with ID 0");
}

function test_CheckUpkeep_TimeExpired() public {
    // Create a raffle
    _createRaffle();
    
    // Fast forward beyond end time
    vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
    
    // Act - check if upkeep is needed
    (bool upkeepNeeded, bytes memory performData) = raffleContract.checkUpkeep("");
    
    // Assert
    assertTrue(upkeepNeeded, "Should need upkeep when raffle time expires");
    
    // Decode the performData
    uint256[] memory raffleIds = abi.decode(performData, (uint256[]));
    assertEq(raffleIds.length, 1, "Should have 1 raffle needing upkeep");
    assertEq(raffleIds[0], 0, "Should be raffle with ID 0");
}

function test_CheckUpkeep_MultipleRafflesNeedUpkeep() public {
    // Create first raffle and sell minimum tickets
    _createRaffle();
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
    vm.stopPrank();
    
    // Create second raffle with shorter duration
    uint256 shortDuration = 1 hours;
    _createRaffleWithCustomParameters(50, 0.1 ether, shortDuration, 5);
    
    // Create third raffle (which we'll leave active)
    _createRaffleWithCustomParameters(50, 0.1 ether, 7 days, 5);
    
    // Fast forward to expire the second raffle
    vm.warp(block.timestamp + shortDuration + 1);
    
    // Act - check if upkeep is needed
    (bool upkeepNeeded, bytes memory performData) = raffleContract.checkUpkeep("");
    
    // Assert
    assertTrue(upkeepNeeded, "Should need upkeep with multiple raffles");
    
    // Decode the performData
    uint256[] memory raffleIds = abi.decode(performData, (uint256[]));
    assertEq(raffleIds.length, 2, "Should have 2 raffles needing upkeep");
    
    // First should be raffle 0 (min tickets reached)
    assertEq(raffleIds[0], 0, "First raffle should be ID 0");
    
    // Second should be raffle 1 (time expired)
    assertEq(raffleIds[1], 1, "Second raffle should be ID 1");
}

function test_PerformUpkeep_SingleRaffle() public {
    // Create a raffle
    _createRaffle();
    
    // Buy tickets
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: MIN_TICKETS_TO_BE_SOLD * TICKET_PRICE}(0, MIN_TICKETS_TO_BE_SOLD);
    vm.stopPrank();
    
    // Get raffle IDs that need upkeep
    (, bytes memory performData) = raffleContract.checkUpkeep("");
    
    // Record logs to check for events
    vm.recordLogs();
    
    // Perform upkeep
    raffleContract.performUpkeep(performData);
    
    // Check that raffle is now inactive
    assertFalse(raffleContract.getRaffleActive(0), "Raffle should be inactive after performUpkeep");
    
    // Verify RandomWordsRequested event was emitted
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bool randomWordsRequested = false;
    uint256 requestId;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
            randomWordsRequested = true;
            requestId = uint256(entries[i].topics[2]);
            break;
        }
    }
    
    assertTrue(randomWordsRequested, "RandomWordsRequested event should be emitted during performUpkeep");
    
    // Complete the process by fulfilling randomness
    uint256[] memory randomWords = new uint256[](1);
    randomWords[0] = 12345;
    
    vm.recordLogs();
    vm.startPrank(address(vrfCoordinatorMock));
    raffleContract.rawFulfillRandomWords(requestId, randomWords);
    vm.stopPrank();
    
    // Verify WinnerSelected event was emitted
    entries = vm.getRecordedLogs();
    bool winnerSelected = false;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("WinnerSelected(uint256,address)")) {
            winnerSelected = true;
            break;
        }
    }
    
    assertTrue(winnerSelected, "WinnerSelected event should be emitted after randomness fulfilled");
}

function test_PerformUpkeep_MultipleRaffles() public {
    // Create two raffles
    _createRaffle(); // Raffle ID 0
    _createRaffleWithCustomParameters(20, 0.1 ether, 1 hours, 5); // Raffle ID 1
    
    // Buy tickets for Raffle 0
    vm.startPrank(buyer1);
    raffleContract.purchaseATicketForARaffle{value: 5 * TICKET_PRICE}(0, 5);
    vm.stopPrank();
    
    // Buy tickets for Raffle 1
    vm.startPrank(buyer2);
    raffleContract.purchaseATicketForARaffle{value: 5 * 0.1 ether}(1, 5);
    vm.stopPrank();
    
    // Fast forward to expire both raffles
    vm.warp(block.timestamp + RAFFLE_LENGTH_IN_SECONDS + 1);
    
    // Get raffle IDs that need upkeep
    (, bytes memory performData) = raffleContract.checkUpkeep("");
    
    // Record logs to check for events
    vm.recordLogs();
    
    // Perform upkeep
    raffleContract.performUpkeep(performData);
    
    // Check that both raffles are now inactive
    assertFalse(raffleContract.getRaffleActive(0), "Raffle 0 should be inactive after performUpkeep");
    assertFalse(raffleContract.getRaffleActive(1), "Raffle 1 should be inactive after performUpkeep");
    
    // Verify RandomWordsRequested events were emitted for both raffles
    Vm.Log[] memory entries = vm.getRecordedLogs();
    uint256 randomWordsRequestCount = 0;
    uint256[] memory requestIds = new uint256[](2);
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("RandomWordsRequested(uint256,uint256)")) {
            requestIds[randomWordsRequestCount] = uint256(entries[i].topics[2]);
            randomWordsRequestCount++;
        }
    }
    
    assertEq(randomWordsRequestCount, 2, "Should have 2 RandomWordsRequested events");
    
    // Complete the process by fulfilling randomness for both requests
    for (uint256 i = 0; i < randomWordsRequestCount; i++) {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456 + i; // Different random words for each
        
        vm.startPrank(address(vrfCoordinatorMock));
        raffleContract.rawFulfillRandomWords(requestIds[i], randomWords);
        vm.stopPrank();
    }
    
    // Verify both raffles have winners
    assertNotEq(raffleContract.getRaffleWinner(0), address(0), "Raffle 0 should have a winner");
    assertNotEq(raffleContract.getRaffleWinner(1), address(0), "Raffle 1 should have a winner");
}


}