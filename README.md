# NFT Raffle Platform

A decentralized platform for creating and participating in NFT raffles with secure random winner selection using Chainlink VRF.

## Overview

The NFT Raffle Platform allows users to:
- Create raffles for their NFTs
- Purchase tickets to participate in raffles
- Win NFTs through a provably fair random selection process
- Get automatic refunds if raffles don't meet minimum participation requirements

## How It Works

### Creating a Raffle

1. **NFT Transfer**: First, you need to approve and transfer your NFT to the raffle contract
2. **Raffle Parameters**:
   - Set the total number of tickets available
   - Set the price per ticket
   - Set the duration of the raffle (1 hour to 30 days)
   - Set minimum number of tickets that must be sold for the raffle to execute

### Participating in a Raffle

1. **Purchase Tickets**: Buy tickets using ETH
2. **Ticket Limits**:
   - Maximum 100 tickets per transaction
   - Each ticket gives you one chance to win
   - You can purchase multiple tickets to increase your chances

### Winner Selection

1. **Automatic Process**:
   - When the raffle ends, a random winner is selected using Chainlink VRF
   - The selection is provably fair and verifiable on-chain
   - The winner automatically receives:
     - The NFT
     - The prize pool (minus platform fees)

### Raffle States

A raffle can be in one of these states:
- **OPEN**: Accepting ticket purchases
- **PENDING_WINNER**: Raffle ended, waiting for random number
- **COMPLETED**: Winner selected and prizes distributed
- **CANCELED**: Raffle canceled due to insufficient participation

### Refund Process

If a raffle is canceled (minimum tickets not sold):
1. The NFT is returned to the original owner
2. All participants automatically receive refunds for their tickets
3. The platform fee is not charged

## Platform Fees

- 10% platform fee on successful raffles
- No fees on canceled raffles

## Security Features

- Reentrancy protection
- Pausable functionality for emergencies
- Secure random number generation using Chainlink VRF
- Automatic refunds for failed raffles
- Checks for minimum participation requirements

## Technical Details

### Smart Contract Features

- Built on Solidity ^0.8.20
- Uses OpenZeppelin contracts for security
- Implements Chainlink VRF for random number generation
- Includes comprehensive event logging
- Gas-optimized for efficient operations

### Key Functions

- `createRaffle`: Create a new NFT raffle
- `purchaseTickets`: Buy tickets for a raffle
- `finalizeRaffle`: Manually end a raffle
- `cancelRaffle`: Cancel a raffle if minimum tickets aren't sold
- `refundParticipant`: Manual refund function (admin only)

## Getting Started

1. Connect your Web3 wallet (MetaMask, etc.)
2. Ensure you have enough ETH for:
   - Ticket purchases
   - Gas fees
3. Browse active raffles or create your own
4. Participate in raffles by purchasing tickets
5. Wait for the raffle to end and winner selection

## Important Notes

- Always verify raffle details before purchasing tickets
- Keep track of raffle end times
- Ensure you have enough ETH for gas fees
- Be aware of the minimum ticket requirement for raffle execution
- Check raffle state before participating

## Support

For technical support or questions, please contact the platform administrators or refer to the smart contract documentation.