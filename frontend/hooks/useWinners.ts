import { useReadContract, useReadContracts } from 'wagmi';
import { baseSepoliaContractAddress } from '@/config';
import raffleAbi from '@/lib/raffleAbi.json';
import { formatEther, Abi } from 'viem';
import { useMemo } from 'react';

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

export function useWinners(pageSize: number = 12, page: number = 1) {
  // 1. Contract reads
  const { data: raffleCounter, isLoading: isLoadingCounter } = useReadContract({
    address: baseSepoliaContractAddress as `0x${string}`,
    abi: raffleAbi as Abi,
    functionName: 'raffleCounter',
  });

  // 2. Calculate pagination
  const totalRaffles = Number(raffleCounter) || 0;
  const startIndex = (page - 1) * pageSize;
  const endIndex = Math.min(startIndex + pageSize, totalRaffles);
  
  console.log('Pagination info:', {
    totalRaffles,
    startIndex,
    endIndex,
    page,
    pageSize
  });
  
  // 3. Generate raffle IDs
  const raffleIds = useMemo(() => 
    Array.from(
      { length: endIndex - startIndex }, 
      (_, i) => startIndex + i
    ),
    [startIndex, endIndex]
  );

  console.log('Fetching raffle IDs:', raffleIds);

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
  const { data: raffles, isLoading: isLoadingRaffles } = useReadContracts({
    contracts: contractCalls,
    query: {
      enabled: raffleIds.length > 0,
      staleTime: 30000, // Cache for 30 seconds
    },
  });

  const isLoading = isLoadingCounter || isLoadingRaffles;

  // 6. Process raffle data
  const completedRaffles = useMemo(() => {
    if (isLoading || !raffles) return [];
    
    return raffles
      .filter((result, index) => {
        if (result.status !== 'success') return false;
        const raffle = result.result as RaffleInfo;
        return raffle.state === 2 && raffle.winner !== '0x0000000000000000000000000000000000000000';
      })
      .map((result, index) => ({
        ...result.result as RaffleInfo,
        actualRaffleId: startIndex + index
      }));
  }, [raffles, startIndex, isLoading]);

  console.log('Completed raffles with IDs:', completedRaffles.map(r => ({
    id: r.actualRaffleId,
    state: r.state,
    winner: r.winner
  })));

  // 7. Format winners
  const formattedWinners = useMemo(() => 
    completedRaffles.map((raffle) => ({
      id: raffle.requestId.toString(),
      winnerAddress: raffle.winner,
      nftAddress: raffle.nftAddress,
      tokenId: raffle.tokenId.toString(),
      wonDate: new Date(Number(raffle.endTime) * 1000).toISOString(),
      ticketPrice: formatEther(raffle.ticketPrice),
      totalTickets: Number(raffle.ticketCount),
      ticketsSold: Number(raffle.totalTicketsSold),
      totalValue: formatEther(raffle.totalPrize),
      raffleId: raffle.actualRaffleId,
    })),
    [completedRaffles]
  );

  console.log('Formatted winners:', formattedWinners);

  if (isLoading || !raffles) {
    return {
      winners: [],
      isLoading: true,
      totalPages: 0,
      currentPage: 1,
    };
  }

  return {
    winners: formattedWinners,
    isLoading,
    totalPages: Math.ceil(totalRaffles / pageSize),
    currentPage: page,
  };
} 