import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  CallbackGasLimitUpdated,
  CoordinatorSet,
  NFTReturned,
  OwnershipTransferRequested,
  OwnershipTransferred,
  Paused,
  PlatformFeeReceived,
  RaffleCancelled,
  RaffleCreated,
  RandomWordsRequested,
  RequestFulfilled,
  RequestSent,
  TicketPurchased,
  TicketsRefunded,
  Unpaused,
  WinnerSelected
} from "../generated/Raffle/Raffle"

export function createCallbackGasLimitUpdatedEvent(
  oldLimit: BigInt,
  newLimit: BigInt
): CallbackGasLimitUpdated {
  let callbackGasLimitUpdatedEvent =
    changetype<CallbackGasLimitUpdated>(newMockEvent())

  callbackGasLimitUpdatedEvent.parameters = new Array()

  callbackGasLimitUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldLimit",
      ethereum.Value.fromUnsignedBigInt(oldLimit)
    )
  )
  callbackGasLimitUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newLimit",
      ethereum.Value.fromUnsignedBigInt(newLimit)
    )
  )

  return callbackGasLimitUpdatedEvent
}

export function createCoordinatorSetEvent(
  vrfCoordinator: Address
): CoordinatorSet {
  let coordinatorSetEvent = changetype<CoordinatorSet>(newMockEvent())

  coordinatorSetEvent.parameters = new Array()

  coordinatorSetEvent.parameters.push(
    new ethereum.EventParam(
      "vrfCoordinator",
      ethereum.Value.fromAddress(vrfCoordinator)
    )
  )

  return coordinatorSetEvent
}

export function createNFTReturnedEvent(
  raffleId: BigInt,
  owner: Address,
  nftAddress: Address,
  tokenId: BigInt
): NFTReturned {
  let nftReturnedEvent = changetype<NFTReturned>(newMockEvent())

  nftReturnedEvent.parameters = new Array()

  nftReturnedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  nftReturnedEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  nftReturnedEvent.parameters.push(
    new ethereum.EventParam(
      "nftAddress",
      ethereum.Value.fromAddress(nftAddress)
    )
  )
  nftReturnedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return nftReturnedEvent
}

export function createOwnershipTransferRequestedEvent(
  from: Address,
  to: Address
): OwnershipTransferRequested {
  let ownershipTransferRequestedEvent =
    changetype<OwnershipTransferRequested>(newMockEvent())

  ownershipTransferRequestedEvent.parameters = new Array()

  ownershipTransferRequestedEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  ownershipTransferRequestedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return ownershipTransferRequestedEvent
}

export function createOwnershipTransferredEvent(
  from: Address,
  to: Address
): OwnershipTransferred {
  let ownershipTransferredEvent =
    changetype<OwnershipTransferred>(newMockEvent())

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return ownershipTransferredEvent
}

export function createPausedEvent(account: Address): Paused {
  let pausedEvent = changetype<Paused>(newMockEvent())

  pausedEvent.parameters = new Array()

  pausedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return pausedEvent
}

export function createPlatformFeeReceivedEvent(
  raffleId: BigInt,
  amount: BigInt
): PlatformFeeReceived {
  let platformFeeReceivedEvent = changetype<PlatformFeeReceived>(newMockEvent())

  platformFeeReceivedEvent.parameters = new Array()

  platformFeeReceivedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  platformFeeReceivedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return platformFeeReceivedEvent
}

export function createRaffleCancelledEvent(
  raffleId: BigInt,
  reason: string
): RaffleCancelled {
  let raffleCancelledEvent = changetype<RaffleCancelled>(newMockEvent())

  raffleCancelledEvent.parameters = new Array()

  raffleCancelledEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  raffleCancelledEvent.parameters.push(
    new ethereum.EventParam("reason", ethereum.Value.fromString(reason))
  )

  return raffleCancelledEvent
}

export function createRaffleCreatedEvent(
  raffleId: BigInt,
  owner: Address,
  nftAddress: Address,
  tokenId: BigInt,
  ticketCount: BigInt,
  endTime: BigInt,
  minTickets: BigInt,
  ticketPrice: BigInt
): RaffleCreated {
  let raffleCreatedEvent = changetype<RaffleCreated>(newMockEvent())

  raffleCreatedEvent.parameters = new Array()

  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "nftAddress",
      ethereum.Value.fromAddress(nftAddress)
    )
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "ticketCount",
      ethereum.Value.fromUnsignedBigInt(ticketCount)
    )
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "minTickets",
      ethereum.Value.fromUnsignedBigInt(minTickets)
    )
  )
  raffleCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "ticketPrice",
      ethereum.Value.fromUnsignedBigInt(ticketPrice)
    )
  )

  return raffleCreatedEvent
}

export function createRandomWordsRequestedEvent(
  raffleId: BigInt,
  requestId: BigInt
): RandomWordsRequested {
  let randomWordsRequestedEvent =
    changetype<RandomWordsRequested>(newMockEvent())

  randomWordsRequestedEvent.parameters = new Array()

  randomWordsRequestedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  randomWordsRequestedEvent.parameters.push(
    new ethereum.EventParam(
      "requestId",
      ethereum.Value.fromUnsignedBigInt(requestId)
    )
  )

  return randomWordsRequestedEvent
}

export function createRequestFulfilledEvent(
  requestId: BigInt,
  randomWords: Array<BigInt>
): RequestFulfilled {
  let requestFulfilledEvent = changetype<RequestFulfilled>(newMockEvent())

  requestFulfilledEvent.parameters = new Array()

  requestFulfilledEvent.parameters.push(
    new ethereum.EventParam(
      "requestId",
      ethereum.Value.fromUnsignedBigInt(requestId)
    )
  )
  requestFulfilledEvent.parameters.push(
    new ethereum.EventParam(
      "randomWords",
      ethereum.Value.fromUnsignedBigIntArray(randomWords)
    )
  )

  return requestFulfilledEvent
}

export function createRequestSentEvent(
  requestId: BigInt,
  numWords: BigInt
): RequestSent {
  let requestSentEvent = changetype<RequestSent>(newMockEvent())

  requestSentEvent.parameters = new Array()

  requestSentEvent.parameters.push(
    new ethereum.EventParam(
      "requestId",
      ethereum.Value.fromUnsignedBigInt(requestId)
    )
  )
  requestSentEvent.parameters.push(
    new ethereum.EventParam(
      "numWords",
      ethereum.Value.fromUnsignedBigInt(numWords)
    )
  )

  return requestSentEvent
}

export function createTicketPurchasedEvent(
  raffleId: BigInt,
  buyer: Address,
  numberOfTickets: BigInt,
  totalPaid: BigInt
): TicketPurchased {
  let ticketPurchasedEvent = changetype<TicketPurchased>(newMockEvent())

  ticketPurchasedEvent.parameters = new Array()

  ticketPurchasedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  ticketPurchasedEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  ticketPurchasedEvent.parameters.push(
    new ethereum.EventParam(
      "numberOfTickets",
      ethereum.Value.fromUnsignedBigInt(numberOfTickets)
    )
  )
  ticketPurchasedEvent.parameters.push(
    new ethereum.EventParam(
      "totalPaid",
      ethereum.Value.fromUnsignedBigInt(totalPaid)
    )
  )

  return ticketPurchasedEvent
}

export function createTicketsRefundedEvent(
  raffleId: BigInt,
  participant: Address,
  amount: BigInt
): TicketsRefunded {
  let ticketsRefundedEvent = changetype<TicketsRefunded>(newMockEvent())

  ticketsRefundedEvent.parameters = new Array()

  ticketsRefundedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  ticketsRefundedEvent.parameters.push(
    new ethereum.EventParam(
      "participant",
      ethereum.Value.fromAddress(participant)
    )
  )
  ticketsRefundedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return ticketsRefundedEvent
}

export function createUnpausedEvent(account: Address): Unpaused {
  let unpausedEvent = changetype<Unpaused>(newMockEvent())

  unpausedEvent.parameters = new Array()

  unpausedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )

  return unpausedEvent
}

export function createWinnerSelectedEvent(
  raffleId: BigInt,
  winner: Address,
  prize: BigInt
): WinnerSelected {
  let winnerSelectedEvent = changetype<WinnerSelected>(newMockEvent())

  winnerSelectedEvent.parameters = new Array()

  winnerSelectedEvent.parameters.push(
    new ethereum.EventParam(
      "raffleId",
      ethereum.Value.fromUnsignedBigInt(raffleId)
    )
  )
  winnerSelectedEvent.parameters.push(
    new ethereum.EventParam("winner", ethereum.Value.fromAddress(winner))
  )
  winnerSelectedEvent.parameters.push(
    new ethereum.EventParam("prize", ethereum.Value.fromUnsignedBigInt(prize))
  )

  return winnerSelectedEvent
}
