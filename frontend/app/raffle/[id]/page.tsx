"use client"

import type React from "react"

import { useState, useEffect, use } from "react";
import Image from "next/image"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { WalletConnect } from "@/components/wallet-connect"
import { CountdownTimer } from "@/components/countdown-timer"
import { ArrowLeft, Clock, Ticket, Users, ExternalLink, AlertCircle } from "lucide-react"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { formatEther } from "viem"
import { useAccount } from 'wagmi';
import { usePurchaseTickets } from "@/hooks/usePurchaseTickets";

type Entry = {
  address: string;
  tickets: number;
  time: string;
};

export default function RaffleDetailPage(props: { params: Promise<{ id: string }> }) {
  const params = use(props.params);
  const [ticketQuantity, setTicketQuantity] = useState(1)
  const [raffle, setRaffle] = useState<any>(null)

  const { isConnected } = useAccount();
  const { purchaseTickets, isLoading, isSuccess, error } = usePurchaseTickets();

  // Add basic feedback for transaction states
  useEffect(() => {
    if (isLoading) {
      console.log("Purchasing tickets...");
    }
    if (isSuccess) {
      console.log("Tickets purchased successfully!");
      // Optionally, refresh raffle data or show a success message
    }
    if (error) {
      console.error("Error purchasing tickets:", error);
      // Optionally, show an error message to the user
    }
  }, [isLoading, isSuccess, error]);

  useEffect(() => {
    // Access params.id here, outside the dependency array declaration
    const raffleId = params.id;

    // Ensure raffleId is available before fetching
    if (raffleId) {
      fetch(`/api/raffle/${raffleId}`)
        .then(res => {
          if (!res.ok) {
            // Log the actual response status and text if not OK
            console.error(`API Error: ${res.status} - ${res.statusText}`);
            return res.text().then(text => { throw new Error(`API error: ${res.status} - ${text}`); });
          }
          return res.json();
        })
        .then(data => {
          // Convert endTime string to Date object
          if (data && data.endTime) {
            data.endTime = new Date(data.endTime);
            console.log("Data", data)
          }
          // Map API response fields to expected state structure
          setRaffle({
            ...data,
            contractAddress: data.nftAddress, // Map nftAddress to contractAddress
            ticketsSold: Number(data.totalTicketsSold), // Map totalTicketsSold and convert from string/BigInt
            maxTickets: Number(data.ticketCount), // Map ticketCount to maxTickets and convert from string/BigInt
            collection: data.collection || "N/A", // Add placeholder for collection if not available
            creator: data.creator || "N/A", // Add placeholder for creator if not available
            recentEntries: data.participants || [], // Map participants to recentEntries (or add a new field) - adjust as needed
          });
        })
        .catch(console.error);
    }

  }, [params.id]); // Keep params.id here to re-run effect when it changes

  if (!raffle) return <div>Loading...</div>

  const handleTicketQuantityChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = Number.parseInt(e.target.value)
    if (value > 0 && value <= raffle.maxTickets - raffle.ticketsSold) {
      setTicketQuantity(value)
    }
  }

  const handleEnterRaffle = () => {
    if (raffle) {
      // Call the purchaseTickets function from the hook
      purchaseTickets(
        BigInt(raffle.id),       // raffleId
        ticketQuantity,          // numberOfTickets
        BigInt(raffle.ticketPrice) // ticketPrice
      );
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
      <div className="container mx-auto px-4">
        <Link href="/" className="mb-8 inline-flex items-center text-purple-400 hover:text-purple-300">
          <ArrowLeft className="mr-2 h-4 w-4" /> Back to raffles
        </Link>

        <div className="grid gap-8 lg:grid-cols-5">
          <div className="lg:col-span-3">
            <div className="mb-8 overflow-hidden rounded-xl bg-slate-800/50 backdrop-blur-sm">
              <div className="relative aspect-square w-full lg:aspect-auto lg:h-[500px]">
                <Image src={raffle.image || "/placeholder.svg"} alt="test" fill className="object-cover" />
              </div>
            </div>

            <div className="mb-8 rounded-xl bg-slate-800/50 p-6 backdrop-blur-sm">
              <h2 className="mb-4 text-xl font-semibold text-white">About this NFT</h2>
              <p className="mb-6 text-slate-300">{raffle.description}</p>

              <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                <div className="rounded-lg bg-slate-700/50 p-3">
                  <h3 className="text-sm text-slate-400">Collection</h3>
                  <p className="font-medium text-white">{raffle.collection}</p>
                </div>
                <div className="rounded-lg bg-slate-700/50 p-3">
                  <h3 className="text-sm text-slate-400">Creator</h3>
                  <p className="font-medium text-white truncate">{raffle.creator}</p>
                </div>
                <div className="rounded-lg bg-slate-700/50 p-3">
                  <h3 className="text-sm text-slate-400">Contract</h3>
                  <div className="flex items-center">
                    <p className="mr-1 font-medium text-white truncate">{raffle.contractAddress ? `${raffle.contractAddress.substring(0, 8)}...` : 'Loading...'}</p>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <ExternalLink className="h-4 w-4 text-slate-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>View on Etherscan</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                </div>
                <div className="rounded-lg bg-slate-700/50 p-3">
                  <h3 className="text-sm text-slate-400">Raffle ID</h3>
                  <p className="font-medium text-white">{raffle.id}</p>
                </div>
              </div>
            </div>

            <div className="rounded-xl bg-slate-800/50 p-6 backdrop-blur-sm">
              <h2 className="mb-4 text-xl font-semibold text-white">Recent Entries</h2>
              <Table>
                <TableHeader>
                  <TableRow className="border-slate-700">
                    <TableHead className="text-slate-300">Address</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(raffle.recentEntries || []).map((entry: string, index: number) => (
                    <TableRow key={index} className="border-slate-700">
                      <TableCell className="font-medium text-white">{entry}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>

              <Accordion type="single" collapsible className="mt-6">
                <AccordionItem value="item-1" className="border-slate-700">
                  <AccordionTrigger className="text-slate-300 hover:text-white">
                    How are winners selected?
                  </AccordionTrigger>
                  <AccordionContent className="text-slate-400">
                    Winners are selected using Chainlink VRF (Verifiable Random Function), which provides a
                    cryptographically secure random number that cannot be manipulated by any party.
                  </AccordionContent>
                </AccordionItem>
                <AccordionItem value="item-2" className="border-slate-700">
                  <AccordionTrigger className="text-slate-300 hover:text-white">
                    What happens after the raffle ends?
                  </AccordionTrigger>
                  <AccordionContent className="text-slate-400">
                    Once the raffle ends, the smart contract automatically selects a winner and transfers the NFT to
                    their wallet. If you win, you'll receive the NFT automatically.
                  </AccordionContent>
                </AccordionItem>
                <AccordionItem value="item-3" className="border-slate-700">
                  <AccordionTrigger className="text-slate-300 hover:text-white">
                    Can I get a refund if I don't win?
                  </AccordionTrigger>
                  <AccordionContent className="text-slate-400">
                    No, raffle ticket purchases are final. The ETH from ticket sales goes to the NFT owner once the
                    raffle concludes.
                  </AccordionContent>
                </AccordionItem>
              </Accordion>
            </div>
          </div>

          <div className="lg:col-span-2">
            <div className="sticky top-6 space-y-6">
              <Card className="overflow-hidden bg-slate-800/50 backdrop-blur-sm">
                <CardContent className="p-6">
                  <h1 className="mb-2 text-2xl font-bold text-white">{raffle.name}</h1>
                  <p className="mb-4 text-slate-400">{raffle.collection}</p>

                  <div className="mb-6 space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center text-slate-300">
                        <Clock className="mr-2 h-5 w-5" />
                        <span>Ends in:</span>
                      </div>
                      <CountdownTimer endTime={raffle.endTime} className="text-lg font-semibold text-white" />
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center text-slate-300">
                        <Ticket className="mr-2 h-5 w-5" />
                        <span>Ticket price:</span>
                      </div>
                      <span className="text-lg font-semibold text-white">{formatEther(BigInt(raffle.ticketPrice))} ETH</span>
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center text-slate-300">
                        <Users className="mr-2 h-5 w-5" />
                        <span>Tickets sold:</span>
                      </div>
                      <span className="text-lg font-semibold text-white">
                        {raffle.ticketsSold} / {raffle.maxTickets}
                      </span>
                    </div>

                    <div>
                      <div className="mb-1 flex justify-between text-sm">
                        <span className="text-slate-400">Progress</span>
                        <span className="text-slate-400">
                          {Math.round((raffle.ticketsSold / raffle.maxTickets) * 100)}%
                        </span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-slate-700">
                        <div
                          className="h-full bg-gradient-to-r from-purple-600 to-pink-600"
                          style={{ width: `${(raffle.ticketsSold / raffle.maxTickets) * 100}%` }}
                        ></div>
                      </div>
                    </div>
                  </div>

                  {!isConnected ? (
                    <div className="space-y-4">
                      <div className="rounded-lg bg-slate-700/50 p-4 text-center">
                        <p className="mb-2 text-slate-300">Connect your wallet to enter this raffle</p>
                        <div >
                          <WalletConnect />
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      <div className="space-y-2">
                        <label htmlFor="quantity" className="block text-sm text-slate-300">
                          Number of tickets
                        </label>
                        <div className="flex items-center gap-2">
                          <Input
                            id="quantity"
                            type="number"
                            min="1"
                            max={raffle.maxTickets - raffle.ticketsSold}
                            value={ticketQuantity}
                            onChange={handleTicketQuantityChange}
                            className="bg-slate-700/50 text-white"
                          />
                          <Button
                            variant="outline"
                            className="border-slate-600 bg-slate-700/50 text-white hover:bg-slate-600"
                            onClick={() => setTicketQuantity(Math.max(1, ticketQuantity - 1))}
                          >
                            -
                          </Button>
                          <Button
                            variant="outline"
                            className="border-slate-600 bg-slate-700/50 text-white hover:bg-slate-600"
                            onClick={() =>
                              setTicketQuantity(Math.min(raffle.maxTickets - raffle.ticketsSold, ticketQuantity + 1))
                            }
                          >
                            +
                          </Button>
                        </div>
                      </div>

                      <div className="rounded-lg bg-slate-700/30 p-4">
                        <div className="mb-2 flex justify-between">
                          <span className="text-slate-300">Cost per ticket:</span>
                          <span className="font-medium text-white">{formatEther(BigInt(raffle.ticketPrice))} ETH</span>
                        </div>
                        <div className="mb-4 flex justify-between">
                          <span className="text-slate-300">Total cost:</span>
                          <span className="font-medium text-white">
                            {formatEther(BigInt(ticketQuantity) * BigInt(raffle.ticketPrice))} ETH
                          </span>
                        </div>
                        <div className="flex items-center text-xs text-slate-400">
                          <AlertCircle className="mr-1 h-3 w-3" />
                          <span>Plus gas fees for the transaction</span>
                        </div>
                      </div>

                      <Button
                        onClick={handleEnterRaffle}
                        className="w-full bg-gradient-to-r from-purple-600 to-pink-600 py-6 text-lg font-semibold"
                        disabled={isLoading}
                      >
                        Enter Raffle
                      </Button>

                      <p className="text-center text-xs text-slate-400">
                        By entering this raffle, you agree to the{" "}
                        <Link href="#" className="text-purple-400 hover:underline">
                          Terms & Conditions
                        </Link>
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>

              <Card className="bg-slate-800/50 backdrop-blur-sm">
                <CardContent className="p-6">
                  <h3 className="mb-4 text-lg font-semibold text-white">Verify Smart Contract</h3>
                  <div className="flex items-center justify-between rounded-lg bg-slate-700/30 p-3">
                    <span className="text-sm text-slate-300">View on Etherscan</span>
                    <ExternalLink className="h-4 w-4 text-purple-400" />
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
