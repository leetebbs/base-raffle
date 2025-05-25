"use client"
import Link from "next/link"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Wallet, Clock, ArrowRight, ExternalLink } from "lucide-react"
import { CountdownTimer } from "@/components/countdown-timer"
import { WalletConnect } from "@/components/wallet-connect"
import { useEffect, useState } from "react";

export default function LandingPage() {

  const [activeRaffles, setActiveRaffles] = useState<any[]>([]);

  useEffect(() => {
    fetch("/api/raffles")
      .then(res => {
        if (!res.ok) throw new Error("API error");
        return res.json();
      })
      .then(setActiveRaffles)
      .catch(console.error);
  }, []);

  return (
    <div className="flex min-h-screen flex-col">
      <main className="flex-1">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-br from-black to-slate-900 py-24 md:py-32">
          <div className="absolute inset-0 opacity-30 mix-blend-overlay">
            <div className="absolute inset-0 bg-[url('/placeholder.svg?height=1080&width=1920')] bg-cover bg-center opacity-20"></div>
          </div>
          <div className="container relative z-10 mx-auto px-4 text-center">
            <h1 className="mb-6 bg-gradient-to-r from-purple-400 via-pink-500 to-amber-500 bg-clip-text text-4xl font-extrabold text-transparent leading-tight md:text-6xl lg:text-7xl">
              Raffle Your NFTs. Win Rare Digital Assets.
            </h1>
            <p className="mx-auto mb-8 max-w-2xl text-lg text-slate-300 md:text-xl">
              Connect your wallet, create or enter raffles using verified NFTs. Transparent, secure, and fun.
            </p>
            <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
              <Link href="/create">
                <Button size="lg" className="w-full bg-gradient-to-r from-purple-600 to-pink-600 sm:w-auto">
                  Create a Raffle
                </Button>
              </Link>
              <Link href="/raffles">
                <Button
                  size="lg"
                  variant="outline"
                  className="w-full border-slate-700 bg-black/50 text-white backdrop-blur-sm sm:w-auto"
                >
                  Browse Raffles
                </Button>
              </Link>
            </div>
            <div className="mt-8 flex justify-center">
              <WalletConnect />
            </div>
          </div>
        </section>

        {/* Active Raffles Section */}
        <section className="bg-slate-900 py-16">
          <div className="container mx-auto px-4">
            <div className="mb-10 flex items-center justify-between">
              <h2 className="text-3xl font-bold text-white">Latest Active Raffles</h2>
              <Link href="/raffles" className="flex items-center text-purple-400 hover:text-purple-300">
                View all <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </div>
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
              {activeRaffles.map((raffle) => (
                <Card key={raffle.id} className="overflow-hidden bg-slate-800/50 backdrop-blur-sm">
                  <div className="relative aspect-square">
                    <Image
                      src={raffle.image || "/placeholder.svg"}
                      alt={raffle.nftAddress}
                      fill
                      className="object-cover p-5"
                    />
                    <Badge className="absolute right-3 top-3 bg-purple-600">
                      {Number(raffle.ticketPrice) / 1e18} ETH
                    </Badge>
                  </div>
                  <CardContent className="p-4">
                    <h3 className="mb-2 text-xl font-bold text-white w-full truncate">
                      <Link href={`https://sepolia.basescan.org/address/${raffle.nftAddress}`} target="_blank" rel="noopener noreferrer" className="flex items-center">
                        <span className="truncate">{raffle.nftAddress}</span>
                        <ExternalLink className="ml-1 h-4 w-4 text-slate-400 hover:text-white" />
                      </Link>
                    </h3>
                    <div className="mb-3 flex items-center text-slate-300">
                      <Clock className="mr-2 h-4 w-4" />
                      <CountdownTimer endTime={new Date(Number(raffle.endTime) * 1000)} />
                    </div>
                    <div className="mb-4">
                      <div className="mb-1 flex justify-between text-sm text-slate-400">
                        <span>Tickets sold</span>
                        <span>
                          {Number(raffle.totalTicketsSold)} / {Number(raffle.ticketCount)}
                        </span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-slate-700">
                        <div
                          className="h-full bg-gradient-to-r from-purple-600 to-pink-600"
                          style={{
                            width: `${(Number(raffle.totalTicketsSold) / Number(raffle.ticketCount)) * 100}%`,
                          }}
                        ></div>
                      </div>
                    </div>
                  </CardContent>
                  <CardFooter className="border-t border-slate-700 p-4">
                    <Link href={`/raffle/${raffle.id}`} className="w-full">
                      <Button className="w-full bg-gradient-to-r from-purple-600 to-pink-600">Enter Raffle</Button>
                    </Link>
                  </CardFooter>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* How It Works Section */}
        <section className="bg-black py-16">
          <div className="container mx-auto px-4">
            <h2 className="mb-12 text-center text-3xl font-bold text-white">How It Works</h2>
            <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
              <div className="rounded-xl bg-slate-800/30 p-6 backdrop-blur-sm">
                <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600">
                  <Wallet className="h-8 w-8 text-white" />
                </div>
                <h3 className="mb-3 text-xl font-bold text-white">Connect your wallet</h3>
                <p className="text-slate-300">
                  Link your Web3 wallet to access your NFTs and participate in raffles securely.
                </p>
              </div>
              <div className="rounded-xl bg-slate-800/30 p-6 backdrop-blur-sm">
                <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="32"
                    height="32"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="h-8 w-8 text-white"
                  >
                    <rect width="18" height="18" x="3" y="3" rx="2" />
                    <path d="M7 7h.01" />
                    <path d="M17 7h.01" />
                    <path d="M7 17h.01" />
                    <path d="M17 17h.01" />
                  </svg>
                </div>
                <h3 className="mb-3 text-xl font-bold text-white">Select an NFT</h3>
                <p className="text-slate-300">
                  Choose an NFT from your wallet to raffle or browse available raffles to enter.
                </p>
              </div>
              <div className="rounded-xl bg-slate-800/30 p-6 backdrop-blur-sm">
                <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="32"
                    height="32"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="h-8 w-8 text-white"
                  >
                    <circle cx="12" cy="12" r="10" />
                    <polyline points="12 6 12 12 16 14" />
                  </svg>
                </div>
                <h3 className="mb-3 text-xl font-bold text-white">Set details & launch</h3>
                <p className="text-slate-300">
                  Set ticket price, duration, and max tickets. Then launch your raffle to the world.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Safety Section */}
        <section className="bg-gradient-to-br from-slate-900 to-black py-16">
          <div className="container mx-auto px-4">
            <div className="mx-auto max-w-3xl rounded-2xl bg-slate-800/30 p-8 backdrop-blur-sm">
              <h2 className="mb-6 text-center text-3xl font-bold text-white">Is this safe?</h2>
              <p className="mb-6 text-center text-lg text-slate-300">
                Absolutely. Our platform uses audited smart contracts deployed on the blockchain, ensuring complete
                transparency and security.
              </p>
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <h3 className="mb-2 font-bold text-purple-400">Verified Smart Contracts</h3>
                  <p className="text-sm text-slate-300">
                    All our contracts are verified on Etherscan and have undergone rigorous security audits.
                  </p>
                </div>
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <h3 className="mb-2 font-bold text-purple-400">Transparent Raffles</h3>
                  <p className="text-sm text-slate-300">
                    Winners are selected using verifiable random functions that cannot be manipulated.
                  </p>
                </div>
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <h3 className="mb-2 font-bold text-purple-400">Secure Escrow</h3>
                  <p className="text-sm text-slate-300">
                    NFTs are held in secure escrow contracts until the raffle concludes and winners are selected.
                  </p>
                </div>
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <h3 className="mb-2 font-bold text-purple-400">Community Governed</h3>
                  <p className="text-sm text-slate-300">
                    Our protocol is governed by the community through our governance token.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
