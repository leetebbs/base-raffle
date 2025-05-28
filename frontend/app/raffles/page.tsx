"use client";

import Image from "next/image"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { CountdownTimer } from "@/components/countdown-timer"
import { useRaffles, FormattedRaffle } from "@/hooks/useRaffles"
import { useState, useEffect } from "react"
import { Search, Clock, Ticket, TrendingUp, FlameIcon as Fire, Star } from "lucide-react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

type Raffle = {
  id: string
  name: string
  image: string
  collection: string
  endTime: Date
  ticketsSold: number
  maxTickets: number
  ticketPrice: number
  status: "active" | "ending-soon"
  featured: boolean
  creator: string
  floorPrice: number
}

export default function BrowseRafflesPage() {
  const [page, setPage] = useState(1);
  const {
    raffles,
    isLoading,
    totalPages,
    currentPage,
    searchQuery,
    setSearchQuery,
    selectedCollection,
    setSelectedCollection,
    priceRange,
    setPriceRange,
    ticketsAvailable,
    setTicketsAvailable,
    timeRemaining,
    setTimeRemaining,
  } = useRaffles(12, page);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "active":
        return <Badge variant="default">Active</Badge>;
      case "ending-soon":
        return <Badge variant="destructive">Ending Soon</Badge>;
      default:
        return null;
    }
  };

  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  const calculateProgress = (sold: number, max: number) => {
    return (sold / max) * 100;
  };

  const filterRafflesByStatus = (status: string) => {
    if (status === "all") return raffles;
    if (status === "featured") return raffles.filter((raffle: FormattedRaffle) => raffle.featured);
    return raffles.filter((raffle: FormattedRaffle) => raffle.status === status);
  }

  const activeRaffles = raffles.length;
  const endingSoonRaffles = raffles.filter((r: FormattedRaffle) => r.status === "ending-soon").length;
  const featuredRaffles = raffles.filter((r: FormattedRaffle) => r.featured).length;
  const totalTicketsSold = raffles.reduce((sum: number, r: FormattedRaffle) => sum + r.ticketsSold, 0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="mb-12 text-center">
          <h1 className="mb-4 bg-gradient-to-r from-purple-400 via-pink-500 to-amber-500 bg-clip-text text-4xl font-extrabold text-transparent md:text-5xl">
            Browse NFT Raffles
          </h1>
          <p className="text-lg text-slate-300 md:text-xl">
            Discover amazing NFTs and enter raffles for a chance to win rare digital assets
          </p>
        </div>

        {/* Quick Stats */}
        <div className="mb-8 grid grid-cols-1 gap-4 md:grid-cols-4">
          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-white">
                {activeRaffles}
              </div>
              <div className="text-sm text-slate-400">Active Raffles</div>
            </CardContent>
          </Card>
          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-white">
                {endingSoonRaffles}
              </div>
              <div className="text-sm text-slate-400">Ending Soon</div>
            </CardContent>
          </Card>
          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-white">
                {featuredRaffles}
              </div>
              <div className="text-sm text-slate-400">Featured</div>
            </CardContent>
          </Card>
          <Card className="bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-white">
                {totalTicketsSold.toLocaleString()}
              </div>
              <div className="text-sm text-slate-400">Total Tickets Sold</div>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
          <CardContent className="p-6">
            <div className="space-y-6">
              {/* Search and Quick Filters */}
              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div className="relative flex-1 lg:max-w-md">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                  <Input
                    placeholder="Search by NFT name, collection, or creator..."
                    className="bg-slate-700/50 pl-10 text-white"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                </div>
                <div className="flex flex-wrap gap-3">
                  <Select value={selectedCollection} onValueChange={setSelectedCollection}>
                    <SelectTrigger className="w-40 bg-slate-700/50 text-white">
                      <SelectValue placeholder="Collection" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 text-white">
                      <SelectItem value="all">All Collections</SelectItem>
                      <SelectItem value="bayc">Bored Ape Yacht Club</SelectItem>
                      <SelectItem value="azuki">Azuki</SelectItem>
                      <SelectItem value="doodles">Doodles</SelectItem>
                      <SelectItem value="cryptopunks">CryptoPunks</SelectItem>
                      <SelectItem value="moonbirds">Moonbirds</SelectItem>
                      <SelectItem value="clonex">Clone X</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={ticketsAvailable} onValueChange={setTicketsAvailable}>
                    <SelectTrigger className="w-40 bg-slate-700/50 text-white">
                      <SelectValue placeholder="Tickets Available" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 text-white">
                      <SelectItem value="any">Any</SelectItem>
                      <SelectItem value="high">{'>'} 50% Available</SelectItem>
                      <SelectItem value="medium">25-50% Available</SelectItem>
                      <SelectItem value="low">{'<'} 25% Available</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={timeRemaining} onValueChange={setTimeRemaining}>
                    <SelectTrigger className="w-40 bg-slate-700/50 text-white">
                      <SelectValue placeholder="Time Remaining" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-800 text-white">
                      <SelectItem value="any">Any</SelectItem>
                      <SelectItem value="1h">Under 1 Hour</SelectItem>
                      <SelectItem value="24h">Under 24 Hours</SelectItem>
                      <SelectItem value="7d">Under 7 Days</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Advanced Filters */}
              <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-300">Ticket Price Range (ETH)</label>
                  <div className="px-2">
                    <Slider
                      value={priceRange}
                      onValueChange={(value) => setPriceRange(value as [number, number])}
                      min={0}
                      max={1}
                      step={0.1}
                      className="py-4"
                    />
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>0 ETH</span>
                      <span>1 ETH</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Raffle Tabs */}
        <Tabs defaultValue="all" className="mb-8">
          <TabsList className="grid w-full grid-cols-4 bg-slate-800/50 lg:w-auto lg:grid-cols-4">
            <TabsTrigger value="all" className="data-[state=active]:bg-purple-600">
              All Raffles
            </TabsTrigger>
            <TabsTrigger value="featured" className="data-[state=active]:bg-purple-600">
              <Star className="mr-1 h-4 w-4" />
              Featured
            </TabsTrigger>
            <TabsTrigger value="ending-soon" className="data-[state=active]:bg-purple-600">
              <Fire className="mr-1 h-4 w-4" />
              Ending Soon
            </TabsTrigger>
            <TabsTrigger value="active" className="data-[state=active]:bg-purple-600">
              Active
            </TabsTrigger>
          </TabsList>

          <TabsContent value="all" className="mt-8">
            <RaffleGrid raffles={filterRafflesByStatus("all")} />
          </TabsContent>
          <TabsContent value="featured" className="mt-8">
            <RaffleGrid raffles={filterRafflesByStatus("featured")} />
          </TabsContent>
          <TabsContent value="ending-soon" className="mt-8">
            <RaffleGrid raffles={filterRafflesByStatus("ending-soon")} />
          </TabsContent>
          <TabsContent value="active" className="mt-8">
            <RaffleGrid raffles={filterRafflesByStatus("active")} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )

  function RaffleGrid({ raffles }: { raffles: FormattedRaffle[] }) {
    if (isLoading) {
      return (
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <Card key={`skeleton-${i}`} className="animate-pulse bg-slate-800/50">
              <div className="aspect-square bg-slate-700" />
              <CardContent className="p-4">
                <div className="h-4 bg-slate-700 rounded w-3/4 mb-2" />
                <div className="h-4 bg-slate-700 rounded w-1/2" />
              </CardContent>
            </Card>
          ))}
        </div>
      );
    }

    if (!raffles || raffles.length === 0) {
      return (
        <div className="text-center py-12">
          <h3 className="text-xl font-semibold text-white mb-2">No raffles found</h3>
          <p className="text-slate-400">
            {searchQuery || selectedCollection !== "all" || ticketsAvailable !== "any" || timeRemaining !== "any"
              ? "Try adjusting your filters"
              : "There are no active raffles at the moment"}
          </p>
        </div>
      );
    }

    return (
      <>
        <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {raffles.map((raffle: FormattedRaffle) => (
            <Card
              key={raffle.id}
              className="group overflow-hidden bg-slate-800/50 backdrop-blur-sm transition-all hover:scale-105 hover:shadow-xl"
            >
              <div className="relative">
                <div className="aspect-square relative">
                  <Image
                    src={raffle.image}
                    alt={raffle.name}
                    fill
                    className="object-cover transition-transform group-hover:scale-110"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.src = '/placeholder.svg';
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

                  {/* Status and Featured Badges */}
                  <div className="absolute left-3 top-3 flex gap-2">
                    {getStatusBadge(raffle.status)}
                    {raffle.featured && (
                      <Badge className="bg-amber-600 hover:bg-amber-700">
                        <Star className="mr-1 h-3 w-3" />
                        Featured
                      </Badge>
                    )}
                  </div>

                  {/* Price Badge */}
                  <Badge className="absolute right-3 top-3 bg-purple-600 text-lg font-bold">
                    {raffle.ticketPrice} ETH
                  </Badge>

                  {/* Floor Price Comparison */}
                  <div className="absolute bottom-3 left-3 rounded-lg bg-black/70 px-2 py-1 text-xs text-white backdrop-blur-sm">
                    Floor: {raffle.floorPrice} ETH
                  </div>
                </div>
              </div>

              <CardContent className="p-4">
                <div className="mb-3">
                  <h3 className="mb-1 text-lg font-bold text-white group-hover:text-purple-400 transition-colors">
                    {raffle.name}
                  </h3>
                  <p className="text-sm text-slate-400">{raffle.collection}</p>
                  <p className="text-xs text-slate-500">by {formatAddress(raffle.creator)}</p>
                </div>

                <div className="mb-4 space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Ends in:</span>
                    <CountdownTimer endTime={raffle.endTime} className="text-white" />
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Tickets:</span>
                    <div className="flex items-center text-white">
                      <Ticket className="mr-1 h-3 w-3" />
                      {raffle.ticketsSold} / {raffle.maxTickets}
                    </div>
                  </div>

                  <div>
                    <div className="mb-1 flex justify-between text-xs text-slate-400">
                      <span>Progress</span>
                      <span>{Math.round(calculateProgress(raffle.ticketsSold, raffle.maxTickets))}%</span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-slate-700">
                      <div
                        className="h-full bg-gradient-to-r from-purple-600 to-pink-600 transition-all"
                        style={{ width: `${calculateProgress(raffle.ticketsSold, raffle.maxTickets)}%` }}
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-slate-400">Total Value:</span>
                    <span className="font-bold text-white">
                      {(raffle.ticketPrice * raffle.maxTickets).toFixed(2)} ETH
                    </span>
                  </div>
                </div>
              </CardContent>

              <CardFooter className="border-t border-slate-700 p-4">
                <Link href={`/raffle/${raffle.id}`} className="w-full">
                  <Button className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700">
                    Enter Raffle
                  </Button>
                </Link>
              </CardFooter>
            </Card>
          ))}
        </div>

        <div className="mt-12 text-center">
          <Button
            variant="outline"
            className="border-slate-700 bg-slate-800/50 text-white hover:bg-slate-700"
            size="lg"
            onClick={() => setPage(p => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
          >
            Load More Raffles
          </Button>
        </div>

        <Card className="mt-12 bg-gradient-to-r from-purple-900/50 to-pink-900/50 backdrop-blur-sm">
          <CardContent className="p-8 text-center">
            <h2 className="mb-4 text-2xl font-bold text-white">Want to create your own raffle?</h2>
            <p className="mb-6 text-slate-300">
              List your NFT and let the community compete for it. Set your own rules and watch the excitement unfold!
            </p>
            <Link href="/create">
              <Button className="bg-gradient-to-r from-purple-600 to-pink-600" size="lg">
                Create a Raffle
              </Button>
            </Link>
          </CardContent>
        </Card>
      </>
    );
  }
}
