"use client"

import React from "react"
import { Button } from "@/components/ui/button"
import { useAccount, useDisconnect } from 'wagmi'
import { useAppKit } from '@reown/appkit/react'

export function WalletConnect() {
  const { address, isConnected } = useAccount()
  const { disconnect } = useDisconnect()
  const { open } = useAppKit() // Get the modal open function

  const connectWallet = () => {
    open() // Open the AppKit modal
  }

  const disconnectWallet = () => {
    disconnect()
  }

  // Helper function to format address (0x123...abc)
  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  return (
    <div>
      {isConnected && address ? (
        <div className="flex items-center gap-2">
          <span className="text-sm truncate max-w-[100px]">{formatAddress(address)}</span>
          <Button onClick={disconnectWallet} variant="outline" size="sm">
            Disconnect
          </Button>
        </div>
      ) : (
        <Button onClick={connectWallet} variant="default" size="sm">
          Connect Wallet
        </Button>
      )}
    </div>
  )
}
