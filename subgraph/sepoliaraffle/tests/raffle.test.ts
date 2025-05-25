import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { CallbackGasLimitUpdated } from "../generated/schema"
import { CallbackGasLimitUpdated as CallbackGasLimitUpdatedEvent } from "../generated/Raffle/Raffle"
import { handleCallbackGasLimitUpdated } from "../src/raffle"
import { createCallbackGasLimitUpdatedEvent } from "./raffle-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let oldLimit = BigInt.fromI32(234)
    let newLimit = BigInt.fromI32(234)
    let newCallbackGasLimitUpdatedEvent = createCallbackGasLimitUpdatedEvent(
      oldLimit,
      newLimit
    )
    handleCallbackGasLimitUpdated(newCallbackGasLimitUpdatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("CallbackGasLimitUpdated created and stored", () => {
    assert.entityCount("CallbackGasLimitUpdated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "CallbackGasLimitUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "oldLimit",
      "234"
    )
    assert.fieldEquals(
      "CallbackGasLimitUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "newLimit",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
