import {
  CallbackGasLimitUpdated as CallbackGasLimitUpdatedEvent,
  CoordinatorSet as CoordinatorSetEvent,
  NFTReturned as NFTReturnedEvent,
  OwnershipTransferRequested as OwnershipTransferRequestedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  Paused as PausedEvent,
  PlatformFeeReceived as PlatformFeeReceivedEvent,
  RaffleCancelled as RaffleCancelledEvent,
  RaffleCreated as RaffleCreatedEvent,
  RandomWordsRequested as RandomWordsRequestedEvent,
  RequestFulfilled as RequestFulfilledEvent,
  RequestSent as RequestSentEvent,
  TicketPurchased as TicketPurchasedEvent,
  TicketsRefunded as TicketsRefundedEvent,
  Unpaused as UnpausedEvent,
  WinnerSelected as WinnerSelectedEvent
} from "../generated/Raffle/Raffle"
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
} from "../generated/schema"

export function handleCallbackGasLimitUpdated(
  event: CallbackGasLimitUpdatedEvent
): void {
  let entity = new CallbackGasLimitUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldLimit = event.params.oldLimit
  entity.newLimit = event.params.newLimit

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCoordinatorSet(event: CoordinatorSetEvent): void {
  let entity = new CoordinatorSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.vrfCoordinator = event.params.vrfCoordinator

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleNFTReturned(event: NFTReturnedEvent): void {
  let entity = new NFTReturned(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.owner = event.params.owner
  entity.nftAddress = event.params.nftAddress
  entity.tokenId = event.params.tokenId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferRequested(
  event: OwnershipTransferRequestedEvent
): void {
  let entity = new OwnershipTransferRequested(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.from = event.params.from
  entity.to = event.params.to

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.from = event.params.from
  entity.to = event.params.to

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePaused(event: PausedEvent): void {
  let entity = new Paused(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.account = event.params.account

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePlatformFeeReceived(
  event: PlatformFeeReceivedEvent
): void {
  let entity = new PlatformFeeReceived(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRaffleCancelled(event: RaffleCancelledEvent): void {
  let entity = new RaffleCancelled(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.reason = event.params.reason

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRaffleCreated(event: RaffleCreatedEvent): void {
  let entity = new RaffleCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.owner = event.params.owner
  entity.nftAddress = event.params.nftAddress
  entity.tokenId = event.params.tokenId
  entity.ticketCount = event.params.ticketCount
  entity.endTime = event.params.endTime
  entity.minTickets = event.params.minTickets
  entity.ticketPrice = event.params.ticketPrice

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRandomWordsRequested(
  event: RandomWordsRequestedEvent
): void {
  let entity = new RandomWordsRequested(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.requestId = event.params.requestId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRequestFulfilled(event: RequestFulfilledEvent): void {
  let entity = new RequestFulfilled(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.requestId = event.params.requestId
  entity.randomWords = event.params.randomWords

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRequestSent(event: RequestSentEvent): void {
  let entity = new RequestSent(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.requestId = event.params.requestId
  entity.numWords = event.params.numWords

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTicketPurchased(event: TicketPurchasedEvent): void {
  let entity = new TicketPurchased(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.buyer = event.params.buyer
  entity.numberOfTickets = event.params.numberOfTickets
  entity.totalPaid = event.params.totalPaid

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTicketsRefunded(event: TicketsRefundedEvent): void {
  let entity = new TicketsRefunded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.participant = event.params.participant
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUnpaused(event: UnpausedEvent): void {
  let entity = new Unpaused(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.account = event.params.account

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleWinnerSelected(event: WinnerSelectedEvent): void {
  let entity = new WinnerSelected(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.raffleId = event.params.raffleId
  entity.winner = event.params.winner
  entity.prize = event.params.prize

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
