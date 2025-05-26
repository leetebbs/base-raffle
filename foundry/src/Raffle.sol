// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/contracts/token/ERC721/IERC721.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/contracts/utils/Pausable.sol";

/**
 * @title Raffle
 * @dev A contract for creating NFT raffles with secure random winner selection using Chainlink VRF
 */
contract Raffle is VRFConsumerBaseV2Plus, ReentrancyGuard, Pausable {
    // Custom errors
    error Raffle__RaffleNotActive();
    error Raffle__RaffleHasEnded();
    error Raffle__NotEnoughTickets();
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleStillActive();
    error Raffle__NoTicketsPurchased();
    error Raffle__TicketCountMustBeMoreThanZero();
    error Raffle__TicketPriceMustBeMoreThanZero();
    error Raffle__NFTTransferFailed();
    error Raffle__RefundFailed();
    error Raffle__PayoutFailed();
    error Raffle__FeeSendFailed();
    error Raffle__RaffleDoesNotExist();
    error Raffle__RequestAlreadyExists();
    error Raffle__RequestNotFound();
    error Raffle__WinnerAlreadySelected();
    error Raffle__RequestNotFulfilled();
    error Raffle__InvalidRaffleDuration();
    error Raffle__MinTicketsExceedTotalTickets();
    error Raffle__TooManyTicketsInOneTransaction();
    error Raffle__RaffleNotInOpenState();
    error Raffle__RaffleNotPendingWinner();
    error Raffle__RaffleCannotBeCancelled();
    error Raffle__NoTicketsToRefund();
    error Raffle__WinnerPayoutFailed();

    // Raffle states
    enum RaffleState {
        OPEN,
        PENDING_WINNER,
        COMPLETED,
        CANCELED
    }

    struct RaffleInfo {
        address nftAddress;
        uint256 tokenId;
        address owner;
        uint256 ticketCount;
        uint256 ticketPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 totalTicketsSold;
        uint256 totalPrize;
        uint256 numberOfTicketsToBeSoldForRaffleToExecute;
        RaffleState state;
        address winner;
        uint256 requestId;
    }

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    // Constants
    uint256 private constant PLATFORM_FEE_PERCENTAGE = 10;
    uint256 private constant WINNER_FEE_PERCENTAGE = 10;
    uint256 private constant MAX_TICKET_PURCHASES_PER_BATCH = 100;
    uint256 public constant MIN_RAFFLE_DURATION = 1 hours;
    uint256 public constant MAX_RAFFLE_DURATION = 30 days;

    // State variables
    uint256 public raffleCounter;
    address public immutable contractOwner;
    address private immutable i_platformWallet;
    uint256 public immutable s_subscriptionId;
    bytes32 private immutable s_keyHash;
    
    // Enhanced gas parameters
    uint32 public callbackGasLimit = 300000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // Mappings
    mapping(uint256 => RaffleInfo) public raffles;
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => uint256) private s_requestIdToRaffleId;
    // Store ticket holders more efficiently
    mapping(uint256 => mapping(uint256 => address)) private raffleTickets;
    // Track ticket purchases per user to enable refunds
    mapping(uint256 => mapping(address => uint256)) public userTicketCounts;
    // Mapping to track raffle participants for more efficient refunds
    mapping(uint256 => address[]) public raffleParticipants;

    // Events
    event TicketPurchased(uint256 indexed raffleId, address indexed buyer, uint256 numberOfTickets, uint256 totalPaid);
    event RaffleCreated(
        uint256 indexed raffleId, 
        address indexed owner, 
        address indexed nftAddress, 
        uint256 tokenId, 
        uint256 ticketCount, 
        uint256 endTime, 
        uint256 minTickets, 
        uint256 ticketPrice
    );
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize);
    event RandomWordsRequested(uint256 indexed raffleId, uint256 indexed requestId);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RaffleCancelled(uint256 indexed raffleId, string reason);
    event TicketsRefunded(uint256 indexed raffleId, address indexed participant, uint256 amount);
    event NFTReturned(uint256 indexed raffleId, address indexed owner, address indexed nftAddress, uint256 tokenId);
    event CallbackGasLimitUpdated(uint32 oldLimit, uint32 newLimit);
    event PlatformFeeReceived(uint256 indexed raffleId, uint256 amount);

    /**
     * @dev Constructor initializes the contract with Chainlink VRF parameters and platform settings
     * @param subscriptionId Chainlink VRF subscription ID
     * @param keyHash Chainlink VRF key hash
     * @param platformWallet Address to receive platform fees
     * @param vrfCoordinator Address of the VRF coordinator
     */
    constructor(
        uint256 subscriptionId,
        bytes32 keyHash,
        address platformWallet,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        i_platformWallet = platformWallet;
        contractOwner = msg.sender;
    }
    
    /**
     * @dev Modifier that restricts access to the contract owner
     */
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Caller is not the contract owner");
        _;
    }

    /**
     * @dev Creates a new raffle
     * @param nftAddress Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param ticketCount Total number of tickets available
     * @param ticketPrice Price per ticket in wei
     * @param raffleLengthInSeconds Duration of the raffle
     * @param minTicketsRequired Minimum number of tickets that must be sold for raffle to be valid
     */
    function createRaffle(
        address nftAddress,
        uint256 tokenId,
        uint256 ticketCount,
        uint256 ticketPrice,
        uint256 raffleLengthInSeconds,
        uint256 minTicketsRequired
    ) external whenNotPaused {
        if (ticketCount == 0) revert Raffle__TicketCountMustBeMoreThanZero();
        if (ticketPrice == 0) revert Raffle__TicketPriceMustBeMoreThanZero();
        if (raffleLengthInSeconds < MIN_RAFFLE_DURATION || raffleLengthInSeconds > MAX_RAFFLE_DURATION) 
            revert Raffle__InvalidRaffleDuration();
        if (minTicketsRequired > ticketCount) revert Raffle__MinTicketsExceedTotalTickets();

        // Transfer NFT to contract safely
        _transferNFTToContract(nftAddress, tokenId);

        // Create the raffle
        _createRaffleInternal(
            nftAddress,
            tokenId,
            ticketCount,
            ticketPrice,
            raffleLengthInSeconds,
            minTicketsRequired
        );
    }
    
    /**
     * @dev Helper function to transfer NFT to contract
     */
    function _transferNFTToContract(address nftAddress, uint256 tokenId) private {
        try IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId) {
            // Transfer successful
        } catch {
            revert Raffle__NFTTransferFailed();
        }
    }
    
    /**
     * @dev Helper function to create a raffle
     */
    function _createRaffleInternal(
        address nftAddress,
        uint256 tokenId,
        uint256 ticketCount,
        uint256 ticketPrice,
        uint256 raffleLengthInSeconds,
        uint256 minTicketsRequired
    ) private {
        uint256 raffleId = raffleCounter;
        uint256 endTime = block.timestamp + raffleLengthInSeconds;
        
        raffles[raffleId] = RaffleInfo({
            nftAddress: nftAddress,
            tokenId: tokenId,
            owner: msg.sender,
            ticketCount: ticketCount,
            ticketPrice: ticketPrice,
            startTime: block.timestamp,
            endTime: endTime,
            totalTicketsSold: 0,
            totalPrize: 0,
            numberOfTicketsToBeSoldForRaffleToExecute: minTicketsRequired,
            state: RaffleState.OPEN,
            winner: address(0),
            requestId: 0
        });

        emit RaffleCreated(
            raffleId,
            msg.sender,
            nftAddress,
            tokenId,
            ticketCount,
            endTime,
            minTicketsRequired,
            ticketPrice
        );

        raffleCounter++;
    }

    /**
     * @dev Allows a user to purchase tickets for a raffle
     * @param raffleId ID of the raffle
     * @param numberOfTickets Number of tickets to purchase
     */
    function purchaseTickets(uint256 raffleId, uint256 numberOfTickets) external payable nonReentrant whenNotPaused {
        RaffleInfo storage raffle = raffles[raffleId];
        if  (numberOfTickets == 0) revert Raffle__NoTicketsPurchased();
        if (raffle.state != RaffleState.OPEN) revert Raffle__RaffleNotActive();
        if (block.timestamp > raffle.endTime) revert Raffle__RaffleHasEnded();
        if (raffle.totalTicketsSold + numberOfTickets > raffle.ticketCount) revert Raffle__NotEnoughTickets();
        if (msg.value != numberOfTickets * raffle.ticketPrice) revert Raffle__NotEnoughEthSent();
        if (numberOfTickets > MAX_TICKET_PURCHASES_PER_BATCH) revert Raffle__TooManyTicketsInOneTransaction();

        _processTicketPurchase(raffleId, numberOfTickets);
    }
    
    /**
     * @dev Helper function to process ticket purchase
     */
    function _processTicketPurchase(uint256 raffleId, uint256 numberOfTickets) private {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Update ticket data structures
        uint256 startIndex = raffle.totalTicketsSold;
        for (uint256 i = 0; i < numberOfTickets; i++) {
            raffleTickets[raffleId][startIndex + i] = msg.sender;
        }
        
        // If this is user's first purchase in this raffle, add to participants list
        if (userTicketCounts[raffleId][msg.sender] == 0) {
            raffleParticipants[raffleId].push(msg.sender);
        }
        
        // Update user's ticket count
        userTicketCounts[raffleId][msg.sender] += numberOfTickets;
        
        // Update raffle stats
        raffle.totalTicketsSold += numberOfTickets;
        raffle.totalPrize += msg.value;

        emit TicketPurchased(raffleId, msg.sender, numberOfTickets, msg.value);

        // Check if raffle conditions are met to end it
        if (_shouldEndRaffle(raffle)) {
            _endRaffle(raffleId);
        }
    }

    /**
     * @dev Internal function to check if a raffle should end
     * @param raffle The raffle info struct
     * @return True if the raffle should end
     */
    function _shouldEndRaffle(RaffleInfo storage raffle) internal view returns (bool) {
        return block.timestamp >= raffle.endTime || raffle.totalTicketsSold >= raffle.ticketCount;
    }

    /**
     * @dev Internal function to end a raffle and initiate winner selection if conditions are met
     * @param raffleId ID of the raffle
     */
    function _endRaffle(uint256 raffleId) internal {
        RaffleInfo storage raffle = raffles[raffleId];
        raffle.state = RaffleState.PENDING_WINNER;
        
        // Only request a winner if minimum tickets were sold
        if (raffle.totalTicketsSold >= raffle.numberOfTicketsToBeSoldForRaffleToExecute) {
            requestRandomWinner(raffleId);
        }
    }

    /**
     * @dev Public function to finalize a raffle that has ended
     * @param raffleId ID of the raffle
     */
    function finalizeRaffle(uint256 raffleId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.OPEN) revert Raffle__RaffleNotInOpenState();
        if (block.timestamp <= raffle.endTime && raffle.totalTicketsSold < raffle.ticketCount) 
            revert Raffle__RaffleStillActive();
            
        _endRaffle(raffleId);
    }

    /**
     * @dev Requests a random winner for a raffle from Chainlink VRF
     * @param raffleId ID of the raffle
     */
    function requestRandomWinner(uint256 raffleId) public {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.PENDING_WINNER) revert Raffle__RaffleNotPendingWinner();
        if (raffle.totalTicketsSold == 0) revert Raffle__NoTicketsPurchased();
        if (raffle.requestId != 0) revert Raffle__RequestAlreadyExists();

        uint256 requestId = _requestRandomWords();
        
        raffle.requestId = requestId;
        s_requestIdToRaffleId[requestId] = raffleId;
        
        emit RandomWordsRequested(raffleId, requestId);
    }

    /**
     * @dev Internal function to request random words from Chainlink VRF
     * @return requestId The ID of the VRF request
     */
    function _requestRandomWords() internal returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0)
        });

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    /**
     * @dev Callback function called by Chainlink VRF when random words are ready
     * @param requestId ID of the VRF request
     * @param randomWords Array of random words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override nonReentrant {
        if (!s_requests[requestId].exists) revert Raffle__RequestNotFound();
        
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWords = randomWords;

        uint256 raffleId = s_requestIdToRaffleId[requestId];
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.PENDING_WINNER) revert Raffle__RaffleNotPendingWinner();

        // Process the winner selection and payouts
        _processWinnerSelection(raffleId, randomWords[0]);
    }
    
    /**
     * @dev Helper function to process winner selection and payouts
     */
    function _processWinnerSelection(uint256 raffleId, uint256 randomWord) private {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Select winner
        uint256 winnerIndex = randomWord % raffle.totalTicketsSold;
        address winner = raffleTickets[raffleId][winnerIndex];
        raffle.winner = winner;
        raffle.state = RaffleState.COMPLETED;

        // Process payments and NFT transfer
        _processWinnerPayouts(raffleId, winner);
    }
    
    /**
     * @dev Helper function to process winner payouts and NFT transfer
     */
    function _processWinnerPayouts(uint256 raffleId, address winner) private {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Calculate payouts
        uint256 platformFee = (raffle.totalPrize * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 winnerPrize = (raffle.totalPrize * WINNER_FEE_PERCENTAGE) / 100; // 10% for winner
        uint256 creatorPayout = raffle.totalPrize - platformFee - winnerPrize; // 80% for creator

        // Transfer prize to winner
        (bool success1, ) = winner.call{value: winnerPrize}("");
        if (!success1) revert Raffle__WinnerPayoutFailed();

        // Transfer fee to platform wallet
        (bool success2, ) = i_platformWallet.call{value: platformFee}("");
        if (!success2) revert Raffle__FeeSendFailed();

        // Transfer creator payout
        (bool success3, ) = raffle.owner.call{value: creatorPayout}("");
        if (!success3) revert Raffle__PayoutFailed();

        // Transfer NFT to winner
        _transferNFTToWinner(raffle.nftAddress, raffle.tokenId, winner);

        emit WinnerSelected(raffleId, winner, winnerPrize);
        emit PlatformFeeReceived(raffleId, platformFee);
    }
    
    /**
     * @dev Helper function to transfer NFT to winner
     */
    function _transferNFTToWinner(address nftAddress, uint256 tokenId, address winner) private {
        try IERC721(nftAddress).transferFrom(address(this), winner, tokenId) {
            // NFT transfer successful
        } catch {
            revert Raffle__NFTTransferFailed();
        }
    }

    /**
     * @dev Cancels a raffle if minimum tickets haven't been sold after end time
     * @param raffleId ID of the raffle
     */
    function cancelRaffle(uint256 raffleId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.PENDING_WINNER && raffle.state != RaffleState.OPEN) 
            revert Raffle__RaffleCannotBeCancelled();
        if (block.timestamp <= raffle.endTime && raffle.state == RaffleState.OPEN) 
            revert Raffle__RaffleStillActive();
            
        // Check if minimum tickets were sold
        if (raffle.totalTicketsSold < raffle.numberOfTicketsToBeSoldForRaffleToExecute) {
            _processCancellation(raffleId);
        } else {
            // If minimum tickets were sold but raffle is in PENDING_WINNER state,
            // request the random winner if not already requested
            if (raffle.requestId == 0) {
                requestRandomWinner(raffleId);
            }
        }
    }
    
    /**
     * @dev Helper function to process raffle cancellation
     */
    function _processCancellation(uint256 raffleId) private {
        RaffleInfo storage raffle = raffles[raffleId];
        raffle.state = RaffleState.CANCELED;
        
        // Return NFT to owner
        try IERC721(raffle.nftAddress).transferFrom(address(this), raffle.owner, raffle.tokenId) {
            emit NFTReturned(raffleId, raffle.owner, raffle.nftAddress, raffle.tokenId);
        } catch {
            revert Raffle__NFTTransferFailed();
        }
        
        // Issue refunds to all participants
        _refundAllParticipants(raffleId);
        
        emit RaffleCancelled(raffleId, "Minimum tickets not sold");
    }

    /**
     * @dev Internal function to refund all participants of a cancelled raffle
     * @param raffleId ID of the raffle
     */
    function _refundAllParticipants(uint256 raffleId) internal {
        RaffleInfo storage raffle = raffles[raffleId];
        address[] memory participants = raffleParticipants[raffleId];
        
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint256 ticketCount = userTicketCounts[raffleId][participant];
            
            if (ticketCount > 0) {
                uint256 refundAmount = ticketCount * raffle.ticketPrice;
                userTicketCounts[raffleId][participant] = 0;
                
                (bool success, ) = participant.call{value: refundAmount}("");
                if (!success) revert Raffle__RefundFailed();
                
                emit TicketsRefunded(raffleId, participant, refundAmount);
            }
        }
    }

    /**
     * @dev Manually trigger refunds for a specific participant
     * @param raffleId ID of the raffle
     * @param participant Address of the participant to refund
     */
    function refundParticipant(uint256 raffleId, address participant) external onlyContractOwner nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (raffle.state != RaffleState.CANCELED) revert Raffle__RaffleCannotBeCancelled();
        
        uint256 ticketCount = userTicketCounts[raffleId][participant];
        if (ticketCount == 0) revert Raffle__NoTicketsToRefund();
        
        uint256 refundAmount = ticketCount * raffle.ticketPrice;
        userTicketCounts[raffleId][participant] = 0;
        
        (bool success, ) = participant.call{value: refundAmount}("");
        if (!success) revert Raffle__RefundFailed();
        
        emit TicketsRefunded(raffleId, participant, refundAmount);
    }

    /**
     * @dev Gets the details of a raffle
     * @param raffleId ID of the raffle
     * @return raffle The raffle information
     */
    function getRaffleInfo(uint256 raffleId) external view returns (RaffleInfo memory) {
        if (raffleId >= raffleCounter) revert Raffle__RaffleDoesNotExist();
        return raffles[raffleId];
    }

    /**
     * @dev Gets the status of a VRF request
     * @param requestId ID of the VRF request
     * @return fulfilled Whether the request has been fulfilled
     * @return randomWords The random words received
     */
    function getRequestStatus(uint256 requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        if (!s_requests[requestId].exists) revert Raffle__RequestNotFound();
        RequestStatus memory req = s_requests[requestId];
        return (req.fulfilled, req.randomWords);
    }

    /**
     * @dev Gets the user's ticket count for a specific raffle
     * @param raffleId ID of the raffle
     * @param user Address of the user
     * @return Number of tickets owned by the user
     */
    function getUserTicketCount(uint256 raffleId, address user) external view returns (uint256) {
        return userTicketCounts[raffleId][user];
    }

    /**
     * @dev Gets all participants of a raffle
     * @param raffleId ID of the raffle
     * @return List of participant addresses
     */
    function getRaffleParticipants(uint256 raffleId) external view returns (address[] memory) {
        return raffleParticipants[raffleId];
    }
    
    /**
     * @dev Updates the callback gas limit for VRF requests
     * @param newGasLimit New gas limit
     */
    function updateCallbackGasLimit(uint32 newGasLimit) external onlyContractOwner {
        uint32 oldLimit = callbackGasLimit;
        callbackGasLimit = newGasLimit;
        emit CallbackGasLimitUpdated(oldLimit, newGasLimit);
    }
    
    /**
     * @dev Pause the contract in case of emergency
     */
    function pause() external onlyContractOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyContractOwner {
        _unpause();
    }

    /**
     * @dev Check if a raffle is active and can receive ticket purchases
     * @param raffleId ID of the raffle
     * @return True if the raffle is active
     */
    function isRaffleActive(uint256 raffleId) external view returns (bool) {
        RaffleInfo storage raffle = raffles[raffleId];
        return raffle.state == RaffleState.OPEN && 
               block.timestamp <= raffle.endTime &&
               raffle.totalTicketsSold < raffle.ticketCount;
    }

    function getKeyHash() external view returns (bytes32) {
    return s_keyHash;
}

function getPlatformWallet() external view returns (address) {
    return i_platformWallet;
}
}