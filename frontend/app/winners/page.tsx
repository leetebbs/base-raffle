"use client"

import Image from "next/image"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import * as Select from "@radix-ui/react-select"
import { Trophy, Calendar, Ticket, ExternalLink, Search, TrendingUp, Users, DollarSign } from "lucide-react"
import { useWinners } from "@/hooks/useWinners"
import { useState, useEffect, useCallback } from "react"
import fetchImageUrl from "@/components/fetchImageUrl"

export default function WinnersPage() {
  const [page, setPage] = useState(1);
  const { winners, isLoading, totalPages, currentPage } = useWinners(12, page);
  const [imageUrls, setImageUrls] = useState<Record<string, string>>({});
  const [loadingImages, setLoadingImages] = useState(true);

  const loadImages = useCallback(async (winnersToLoad: any[]) => {
    if (winnersToLoad.length === 0) return;
    
    setLoadingImages(true);
    const urls: Record<string, string> = {};
    
    for (const winner of winnersToLoad) {
      try {
        const imageUrl = await fetchImageUrl(winner.nftAddress as `0x${string}`, BigInt(winner.tokenId));
        urls[winner.id] = imageUrl;
      } catch (error) {
        console.error(`Error loading image for NFT ${winner.tokenId}:`, error);
        urls[winner.id] = '/placeholder-nft.png';
      }
    }
    
    setImageUrls(prev => ({ ...prev, ...urls }));
    setLoadingImages(false);
  }, []);

  useEffect(() => {
    if (winners.length > 0) {
      loadImages(winners);
    }
  }, []);

  // Platform statistics
  const stats = {
    totalWinners: winners.length,
    totalValueWon: winners.reduce((acc, winner) => acc + Number(winner.totalValue), 0),
    totalRafflesCompleted: winners.length,
    averageTicketsSold: winners.length > 0 
      ? Math.round(winners.reduce((acc, winner) => acc + winner.ticketsSold, 0) / winners.length)
      : 0,
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }

  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`
  }

  const calculateWinChance = (winnerTickets: number, totalTickets: number) => {
    return ((winnerTickets / totalTickets) * 100).toFixed(2)
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
        <div className="container mx-auto px-4">
          <div className="text-center text-white">Loading winners...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-12 text-center">
          <h1 className="mb-4 bg-gradient-to-r from-purple-400 via-pink-500 to-amber-500 bg-clip-text text-4xl font-extrabold text-transparent md:text-5xl">
            Recent Winners
          </h1>
          <p className="text-lg text-slate-300 md:text-xl">
            Celebrate with our lucky winners who took home amazing NFTs!
          </p>
        </div>

        {/* Platform Statistics */}
        <div className="mb-12 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-6">
              <div className="flex items-center">
                <div className="rounded-full bg-purple-600 p-3">
                  <Trophy className="h-6 w-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm text-slate-400">Total Winners</p>
                  <p className="text-2xl font-bold text-white">{stats.totalWinners.toLocaleString()}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-6">
              <div className="flex items-center">
                <div className="rounded-full bg-green-600 p-3">
                  <DollarSign className="h-6 w-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm text-slate-400">Total Value Won</p>
                  <p className="text-2xl font-bold text-white">{stats.totalValueWon.toFixed(2)} ETH</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-6">
              <div className="flex items-center">
                <div className="rounded-full bg-blue-600 p-3">
                  <TrendingUp className="h-6 w-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm text-slate-400">Completed Raffles</p>
                  <p className="text-2xl font-bold text-white">{stats.totalRafflesCompleted.toLocaleString()}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-6">
              <div className="flex items-center">
                <div className="rounded-full bg-amber-600 p-3">
                  <Users className="h-6 w-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm text-slate-400">Avg. Participation</p>
                  <p className="text-2xl font-bold text-white">{stats.averageTicketsSold} tickets</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
          <CardContent className="p-6">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div className="flex flex-col gap-4 sm:flex-row">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                  <Input
                    placeholder="Search by NFT name or collection..."
                    className="w-full bg-slate-700/50 pl-10 text-white sm:w-80"
                  />
                </div>
                <Select.Root>
                  <Select.Trigger className="w-full bg-slate-700/50 text-white sm:w-48">
                    <Select.Value placeholder="Filter by collection" />
                  </Select.Trigger>
                  <Select.Content className="bg-slate-800 text-white">
                    <Select.Item value="all">All Collections</Select.Item>
                    <Select.Item value="bayc">Bored Ape Yacht Club</Select.Item>
                    <Select.Item value="azuki">Azuki</Select.Item>
                    <Select.Item value="doodles">Doodles</Select.Item>
                    <Select.Item value="cryptopunks">CryptoPunks</Select.Item>
                    <Select.Item value="moonbirds">Moonbirds</Select.Item>
                  </Select.Content>
                </Select.Root>
              </div>
              <Select.Root>
                <Select.Trigger className="w-full bg-slate-700/50 text-white sm:w-48">
                  <Select.Value placeholder="Sort by" />
                </Select.Trigger>
                <Select.Content className="bg-slate-800 text-white">
                  <Select.Item value="recent">Most Recent</Select.Item>
                  <Select.Item value="value">Highest Value</Select.Item>
                  <Select.Item value="tickets">Most Tickets</Select.Item>
                </Select.Content>
              </Select.Root>
            </div>
          </CardContent>
        </Card>

        {/* Winners Grid */}
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-6">
          {winners.map((winner) => (
            <Card
              key={winner.id}
              className="overflow-hidden bg-slate-800/50 backdrop-blur-sm transition-all hover:scale-105"
            >
              <div className="relative">
                <div className="aspect-square relative">
                  {loadingImages ? (
                    <div className="w-full h-full bg-slate-700 animate-pulse" />
                  ) : (
                    <Image
                      src={imageUrls[winner.id] || '/placeholder-nft.png'}
                      alt={`NFT #${winner.tokenId}`}
                      fill
                      className="object-cover"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = '/placeholder-nft.png';
                      }}
                    />
                  )}
                  <Badge className="absolute right-3 top-3 bg-gradient-to-r from-purple-600 to-pink-600">
                    <Trophy className="mr-1 h-3 w-3" />
                    Winner
                  </Badge>
                </div>
              </div>

              <CardContent className="p-6">
                <div className="mb-4">
                  <h3 className="mb-1 text-xl font-bold text-white">NFT #{winner.tokenId}</h3>
                  <p className="text-sm text-slate-400">{winner.nftAddress}</p>
                </div>

                <div className="mb-4 space-y-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Winner:</span>
                    <span className="font-mono text-white">{formatAddress(winner.winnerAddress)}</span>
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Won on:</span>
                    <div className="flex items-center text-white">
                      <Calendar className="mr-1 h-3 w-3" />
                      {formatDate(winner.wonDate)}
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Tickets sold:</span>
                    <div className="flex items-center text-white">
                      <Ticket className="mr-1 h-3 w-3" />
                      {winner.ticketsSold} / {winner.totalTickets}
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Total value:</span>
                    <span className="font-bold text-white">{winner.totalValue} ETH</span>
                  </div>
                </div>

                <div className="space-y-3">
                  <div className="rounded-lg bg-slate-700/30 p-3">
                    <div className="mb-1 flex justify-between text-xs text-slate-400">
                      <span>Raffle Progress</span>
                      <span>{Math.round((winner.ticketsSold / winner.totalTickets) * 100)}%</span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-slate-600">
                      <div
                        className="h-full bg-gradient-to-r from-purple-600 to-pink-600"
                        style={{ width: `${(winner.ticketsSold / winner.totalTickets) * 100}%` }}
                      ></div>
                    </div>
                  </div>

                  <Link href={`/raffle/${winner.raffleId}`}>
                    <Button
                      variant="outline"
                      className="w-full border-slate-600 bg-slate-700/50 text-white hover:bg-slate-600"
                    >
                      View Raffle Details
                      <ExternalLink className="ml-2 h-4 w-4" />
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Load More */}
        <div className="mt-12 text-center">
          <div className="flex justify-center gap-4">
            <Button 
              variant="outline" 
              className="border-slate-700 bg-slate-800/50 text-white hover:bg-slate-700"
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
            >
              Previous Page
            </Button>
            <span className="flex items-center px-4 text-white">
              Page {currentPage} of {totalPages}
            </span>
            <Button 
              variant="outline" 
              className="border-slate-700 bg-slate-800/50 text-white hover:bg-slate-700"
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
            >
              Next Page
            </Button>
          </div>
        </div>

        {/* Call to Action */}
        <Card className="mt-12 bg-gradient-to-r from-purple-900/50 to-pink-900/50 backdrop-blur-sm">
          <CardContent className="p-8 text-center">
            <Trophy className="mx-auto mb-4 h-12 w-12 text-amber-400" />
            <h2 className="mb-4 text-2xl font-bold text-white">Want to be the next winner?</h2>
            <p className="mb-6 text-slate-300">
              Join active raffles and get a chance to win amazing NFTs from top collections!
            </p>
            <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
              <Link href="/raffles">
                <Button
                  variant="outline"
                  className="border-purple-600 bg-purple-600/20 text-white hover:bg-purple-600/30"
                >
                  Browse Active Raffles
                </Button>
              </Link>
              <Link href="/create">
                <Button className="bg-gradient-to-r from-purple-600 to-pink-600">Create Your Own Raffle</Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
