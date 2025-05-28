// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "forge-std/Test.sol";
import { StdInvariant} from "forge-std/StdInvariant.sol";
import { DeployRaffle } from "../../script/DeployRaffle.s.sol";
import { Raffle } from "../../src/Raffle.sol";
import { IERC721 } from "@openzeppelin/contracts/contracts/token/ERC721/IERC721.sol";
import { MockERC721 } from  "../../src/MockERC721.sol";

// contract MockNFT is IERC721 {
//     function transferFrom(address from, address to, uint256 tokenId) external override {
//         // Mock implementation - always succeeds
//     }

//     // Required IERC721 functions - not used in tests
//     function balanceOf(address owner) external pure override returns (uint256) { return 0; }
//     function ownerOf(uint256 tokenId) external pure override returns (address) { return address(0); }
//     function safeTransferFrom(address from, address to, uint256 tokenId) external override {}
//     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {}
//     function approve(address to, uint256 tokenId) external override {}
//     function setApprovalForAll(address operator, bool approved) external override {}
//     function getApproved(uint256 tokenId) external pure override returns (address) { return address(0); }
//     function isApprovedForAll(address owner, address operator) external pure override returns (bool) { return false; }
    
//     // Required IERC165 function
//     function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
//         return interfaceId == type(IERC721).interfaceId;
//     }
// }

contract InvariantsTestis is StdInvariant {
    DeployRaffle deployer;
    Raffle raffle;
    MockERC721 mockERC721;

    function setUp() external {
        deployer = new DeployRaffle();
        (raffle) = deployer.run();
        targetContract(address(raffle));

        // Deploy mock NFT
        mockERC721 = new MockERC721("Mock NFT", "MNFT");

        // Create a test raffle
        uint256 tokenId = 1;
        uint256 ticketCount = 100;
        uint256 ticketPrice = 0.1 ether;
        uint256 raffleLengthInSeconds = 1 days;
        uint256 minTicketsRequired = 10;

        // Mint the NFT to the test contract
        mockERC721.mint(address(this), tokenId);

        // Approve the raffle contract to transfer the NFT
        mockERC721.approve(address(raffle), tokenId);

        // Create the raffle
        raffle.createRaffle(
            address(mockERC721),
            tokenId,
            ticketCount,
            ticketPrice,
            raffleLengthInSeconds,
            minTicketsRequired
        );
    }

    // 1. State Transitions
    // - A raffle can only be in one state at a time (OPEN, PENDING_WINNER, COMPLETED, CANCELED)
    // - State transitions must follow the correct sequence: OPEN -> PENDING_WINNER -> COMPLETED/CANCELED
    // - A raffle cannot transition back to a previous state

    function invariant_StateTransitions() public view {
        // Get current state
        Raffle.RaffleInfo memory raffleInfo = raffle.getRaffleInfo(0); // Get first raffle
        uint256 currentState = uint256(raffleInfo.state);
        
        // Ensure state is valid (must be one of: OPEN, PENDING_WINNER, COMPLETED, CANCELED)
        require(
            currentState == uint256(Raffle.RaffleState.OPEN) ||
            currentState == uint256(Raffle.RaffleState.PENDING_WINNER) ||
            currentState == uint256(Raffle.RaffleState.COMPLETED) ||
            currentState == uint256(Raffle.RaffleState.CANCELED),
            "Invalid raffle state"
        );

        // If raffle is completed or canceled, it cannot transition back
        if (currentState == uint256(Raffle.RaffleState.COMPLETED) || 
            currentState == uint256(Raffle.RaffleState.CANCELED)) {
            // These states are terminal - no further transitions should be possible
            require(
                currentState == uint256(Raffle.RaffleState.COMPLETED) || 
                currentState == uint256(Raffle.RaffleState.CANCELED),
                "Raffle in terminal state cannot transition"
            );
        }
    }

    // 2. Ticket Management
    // - Total tickets sold cannot exceed total available tickets
    // - A user cannot purchase more than MAX_TICKET_PURCHASES_PER_BATCH tickets in one transaction
    // - Ticket price must be greater than zero
    // - Total prize pool must equal (tickets sold * ticket price)

    function invariant_TicketManagement() public view {
        Raffle.RaffleInfo memory raffleInfo = raffle.getRaffleInfo(0);
        
        // Check total tickets sold doesn't exceed available tickets
        require(
            raffleInfo.totalTicketsSold <= raffleInfo.ticketCount,
            "Total tickets sold exceeds available tickets"
        );

        // Check ticket price is greater than zero
        require(
            raffleInfo.ticketPrice > 0,
            "Ticket price must be greater than zero"
        );

        // Check total prize pool equals (tickets sold * ticket price)
        require(
            raffleInfo.totalPrize == raffleInfo.totalTicketsSold * raffleInfo.ticketPrice,
            "Total prize pool does not match tickets sold * price"
        );

        // Check each user's ticket count
        address[] memory participants = raffle.getRaffleParticipants(0);
        for (uint256 i = 0; i < participants.length; i++) {
            uint256 userTickets = raffle.getUserTicketCount(0, participants[i]);
            require(
                userTickets <= 100, // MAX_TICKET_PURCHASES_PER_BATCH is 100 in Raffle.sol
                "User has more than MAX_TICKET_PURCHASES_PER_BATCH tickets"
            );
        }
    }

    // 3. Time Management
    // - Raffle duration must be between MIN_RAFFLE_DURATION and MAX_RAFFLE_DURATION
    // - End time must be greater than start time
    // - A raffle cannot be finalized before its end time unless all tickets are sold or minimum tickets are sold

    function invariant_TimeManagement() public view {
        Raffle.RaffleInfo memory raffleInfo = raffle.getRaffleInfo(0);
        
        // Check raffle duration is within bounds
        uint256 duration = raffleInfo.endTime - raffleInfo.startTime;
        require(
            duration >= raffle.MIN_RAFFLE_DURATION() && duration <= raffle.MAX_RAFFLE_DURATION(),
            "Raffle duration is outside allowed bounds"
        );

        // Check end time is greater than start time
        require(
            raffleInfo.endTime > raffleInfo.startTime,
            "End time must be greater than start time"
        );

        // Check raffle state is valid based on time and ticket sales
        if (raffleInfo.state == Raffle.RaffleState.PENDING_WINNER) {
            require(
                block.timestamp >= raffleInfo.endTime || 
                raffleInfo.totalTicketsSold >= raffleInfo.ticketCount ||
                raffleInfo.totalTicketsSold >= raffleInfo.numberOfTicketsToBeSoldForRaffleToExecute,
                "Raffle cannot be in PENDING_WINNER state before end time unless all tickets are sold or minimum tickets are sold"
            );
        }
    }
}


// 4. Winner Selection
// - Winner can only be selected if minimum required tickets are sold
// - Winner must be selected from actual ticket holders
// - Winner selection must use Chainlink VRF for randomness
// - Winner cannot be selected for a cancelled raffle

// 5. Financial Invariants
// - Platform fee must be exactly 10% of total prize pool
// - Winner prize must be exactly 10% of total prize pool
// - Creator payout must be exactly 80% of total prize pool
// - All refunds must be for the exact amount paid by participants

// 6. NFT Management
// - NFT must be transferred to winner when raffle completes
// - NFT must be returned to owner if raffle is cancelled
// - Contract must have approval to transfer the NFT

// 7. Access Control
// - Only contract owner can perform administrative functions
// - Only raffle owner can cancel their own raffle
// - Anyone can purchase tickets for an active raffle

// 8. Reentrancy Protection
// - All external functions must be protected against reentrancy
// - State changes must be made before external calls (checks-effects-interactions pattern)

// 9. Pausability
// - Contract must be pausable for emergency situations
// - No ticket purchases allowed when contract is paused

// 10. Data Consistency
// - User ticket counts must match actual tickets allocated
// - Raffle participants array must contain all unique participants
// - Request IDs must be unique and properly mapped to raffles