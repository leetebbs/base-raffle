import { useReadContract, useReadContracts } from 'wagmi';
import { baseSepoliaContractAddress } from '@/config';
import raffleAbi from '@/lib/raffleAbi.json';
import { formatEther, Abi } from 'viem';
import { useMemo, useState, useEffect } from 'react';
import fetchImageUrl from '@/components/fetchImageUrl';

// Debug logging
console.log('Contract Address:', baseSepoliaContractAddress);
console.log('Contract ABI:', raffleAbi);

// IPFS Gateway URLs
const IPFS_GATEWAYS = [
  'https://ipfs.io/ipfs/',
  'https://gateway.pinata.cloud/ipfs/',
  'https://cloudflare-ipfs.com/ipfs/',
  'https://ipfs.infura.io/ipfs/',
];

function getIpfsUrl(ipfsUrl: string): string {
  if (!ipfsUrl) return '/placeholder.svg?height=400&width=400';
  
  // If it's already a regular URL, return it
  if (ipfsUrl.startsWith('http')) return ipfsUrl;
  
  // If it's an IPFS URL, convert it
  if (ipfsUrl.startsWith('ipfs://')) {
    const ipfsHash = ipfsUrl.replace('ipfs://', '');
    return `${IPFS_GATEWAYS[0]}${ipfsHash}`;
  }
  
  return '/placeholder.svg?height=400&width=400';
}

interface RaffleInfo {
  nftAddress: string;
  tokenId: bigint;
  owner: string;
  ticketCount: bigint;
  ticketPrice: bigint;
  startTime: bigint;
  endTime: bigint;
  totalTicketsSold: bigint;
  totalPrize: bigint;
  numberOfTicketsToBeSoldForRaffleToExecute: bigint;
  state: number;
  winner: string;
  requestId: bigint;
}

export interface FormattedRaffle {
  id: string;
  nftAddress: string;
  tokenId: string;
  name: string;
  image: string;
  collection: string;
  endTime: Date;
  ticketsSold: number;
  maxTickets: number;
  ticketPrice: number;
  status: "active" | "ending-soon";
  featured: boolean;
  creator: string;
  floorPrice: number;
}

export function useRaffles(pageSize: number = 12, page: number = 1) {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCollection, setSelectedCollection] = useState("all");
  const [priceRange, setPriceRange] = useState<[number, number]>([0, 0.5]);
  const [ticketsAvailable, setTicketsAvailable] = useState("any");
  const [timeRemaining, setTimeRemaining] = useState("any");
  const [formattedRaffles, setFormattedRaffles] = useState<FormattedRaffle[]>([]);

  // 1. Contract reads
  const { data: raffleCounter, isLoading: isLoadingCounter, error: counterError } = useReadContract({
    address: baseSepoliaContractAddress as `0x${string}`,
    abi: raffleAbi as Abi,
    functionName: 'raffleCounter',
  });

  // 2. Calculate pagination
  const totalRaffles = Number(raffleCounter) || 0;
  const startIndex = (page - 1) * pageSize;
  const endIndex = Math.min(startIndex + pageSize, totalRaffles);

  // 3. Generate raffle IDs
  const raffleIds = useMemo(() => 
    Array.from(
      { length: endIndex - startIndex }, 
      (_, i) => startIndex + i
    ),
    [startIndex, endIndex]
  );

  // 4. Prepare contract calls
  const contractCalls = useMemo(() => 
    raffleIds.map(id => ({
      address: baseSepoliaContractAddress as `0x${string}`,
      abi: raffleAbi as Abi,
      functionName: 'getRaffleInfo',
      args: [id],
    })),
    [raffleIds]
  );

  // 5. Fetch raffle data
  const { data: raffles, isLoading: isLoadingRaffles, error: rafflesError } = useReadContracts({
    contracts: contractCalls,
    query: {
      enabled: raffleIds.length > 0,
      staleTime: 30000, // Cache for 30 seconds
    },
  });

  const isLoading = isLoadingCounter || isLoadingRaffles;

  // 6. Process raffle data
  useEffect(() => {
    if (isLoading || !raffles) {
      setFormattedRaffles([]);
      return;
    }

    const processRaffles = async () => {
      const activeRaffles = raffles
        .filter((result): result is { status: 'success'; result: RaffleInfo } => {
          if (result.status !== 'success') {
            return false;
          }
          const raffle = result.result as RaffleInfo;
          // State 0: Not started, State 1: Active, State 2: Completed
          const isActive = raffle.state === 0 || raffle.state === 1;
          return isActive;
        })
        .map(async (result) => {
          const raffle = result.result;
          const endTime = new Date(Number(raffle.endTime) * 1000);
          const now = new Date();
          const hoursUntilEnd = (endTime.getTime() - now.getTime()) / (1000 * 60 * 60);
          
          // Use fetchImageUrl to get the proper image URL
          const imageUrl = await fetchImageUrl(raffle.nftAddress as `0x${string}`, raffle.tokenId);
          
          return {
            id: raffle.requestId.toString(),
            nftAddress: raffle.nftAddress,
            tokenId: raffle.tokenId.toString(),
            name: `NFT #${raffle.tokenId}`,
            image: imageUrl || '/placeholder.svg',
            collection: "Unknown Collection", // TODO: Fetch collection name
            endTime,
            ticketsSold: Number(raffle.totalTicketsSold),
            maxTickets: Number(raffle.ticketCount),
            ticketPrice: Number(formatEther(raffle.ticketPrice)),
            status: hoursUntilEnd <= 24 ? "ending-soon" : "active",
            featured: false, // TODO: Implement featured logic
            creator: raffle.owner,
            floorPrice: 0, // TODO: Fetch floor price
          } as FormattedRaffle;
        });

      const processedRaffles = await Promise.all(activeRaffles);
      setFormattedRaffles(processedRaffles);
    };

    processRaffles();
  }, [raffles, startIndex, isLoading]);

  // 7. Apply filters
  const filteredRaffles = useMemo(() => {
    return formattedRaffles.filter((raffle) => {
      // Search filter
      if (searchQuery && !raffle.name.toLowerCase().includes(searchQuery.toLowerCase()) &&
          !raffle.collection.toLowerCase().includes(searchQuery.toLowerCase()) &&
          !raffle.creator.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }

      // Collection filter
      if (selectedCollection !== "all" && raffle.collection !== selectedCollection) {
        return false;
      }

      // Price range filter
      if (raffle.ticketPrice < priceRange[0] || raffle.ticketPrice > priceRange[1]) {
        return false;
      }

      // Tickets available filter
      const ticketsAvailablePercent = ((raffle.maxTickets - raffle.ticketsSold) / raffle.maxTickets) * 100;
      if (ticketsAvailable === "high" && ticketsAvailablePercent <= 50) return false;
      if (ticketsAvailable === "medium" && (ticketsAvailablePercent <= 25 || ticketsAvailablePercent > 50)) return false;
      if (ticketsAvailable === "low" && ticketsAvailablePercent > 25) return false;

      // Time remaining filter
      const hoursUntilEnd = (raffle.endTime.getTime() - new Date().getTime()) / (1000 * 60 * 60);
      if (timeRemaining === "1h" && hoursUntilEnd > 1) return false;
      if (timeRemaining === "24h" && hoursUntilEnd > 24) return false;
      if (timeRemaining === "7d" && hoursUntilEnd > 168) return false;

      return true;
    });
  }, [formattedRaffles, searchQuery, selectedCollection, priceRange, ticketsAvailable, timeRemaining]);

  // Debug logging
  useEffect(() => {
    if (counterError) {
      console.error('Counter Error:', counterError);
    }
    if (rafflesError) {
      console.error('Raffles Error:', rafflesError);
    }
    if (raffleCounter !== undefined) {
      console.log('Raffle Counter:', raffleCounter);
    }
    if (raffles) {
      console.log('Raw Raffle Data:', raffles);
    }
  }, [counterError, rafflesError, raffleCounter, raffles]);

  return {
    raffles: filteredRaffles,
    isLoading,
    totalPages: Math.ceil(totalRaffles / pageSize),
    currentPage: page,
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
  };
} 