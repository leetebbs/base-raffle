import { NextResponse } from 'next/server';
import { createPublicClient, http, getContract } from 'viem';
import { baseSepolia } from 'viem/chains';
import RaffleABI from '@/lib/raffleAbi.json'; // Corrected ABI import
import ERC721ABI from '@/lib/erc721Abi.json'; // Assuming you have a minimal ERC721 ABI with tokenURI here
import { baseSepoliaContractAddress } from '../../../../config'

const raffleContractAddress = baseSepoliaContractAddress; // Replace with your contract address

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http()
});

// Define RaffleInfo type based on your contract struct (updated to reflect named properties)
type RaffleInfo = {
  nftAddress: string; // index 0
  tokenId: bigint; // index 1
  owner: string; // index 2
  ticketCount: bigint; // index 3 (max tickets)
  ticketPrice: bigint; // index 4
  startTime: bigint; // index 5
  endTime: bigint; // index 6
  totalTicketsSold: bigint; // index 7
  totalPrize: bigint; // index 8
  numberOfTicketsToBeSoldForRaffleToExecute: bigint; // index 9
  state: number; // index 10 (enum uint8)
  winner: string; // index 11
  requestId: bigint;  // index 12
};

// Mapping for RaffleState enum from the contract
const RaffleStateMapping: { [key: number]: string } = {
  0: 'OPEN',
  1: 'PENDING_WINNER',
  2: 'COMPLETED',
  3: 'CANCELED'
};

// Helper function to convert IPFS URL to a gateway URL
const ipfsToGatewayUrl = (ipfsUrl: string) => {
  if (!ipfsUrl) return "/placeholder.svg"; // Default placeholder
  if (ipfsUrl.startsWith("ipfs://")) {
    const cid = ipfsUrl.replace("ipfs://", "");
    return `https://ipfs.io/ipfs/${cid}`;
  }
  // Return the original URL if it's not an IPFS URL or another protocol
  return ipfsUrl;
};

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const userAddress = searchParams.get('address');

  if (!userAddress) {
    return NextResponse.json({ error: 'Wallet address is required.' }, { status: 400 });
  }

  console.log("API: Fetching created raffles for address:", userAddress);

  try {
    const raffleContract = getContract({
      address: raffleContractAddress as `0x${string}`,
      abi: RaffleABI as any, // Casting to any for compatibility, ideally use 'as const'
      client: publicClient
    });

    const raffleCounter = await raffleContract.read.raffleCounter([]);
    const totalRaffles = Number(raffleCounter);
    console.log("Total raffles found:", totalRaffles);

    const createdRafflesDetails: any[] = [];

    // Iterate through all raffles to find those the user has created
    for (let i = 0; i < totalRaffles; i++) {
      console.log(`Checking raffle ${i} for creator ${userAddress}`);
      let raffleInfo: RaffleInfo | undefined;
      try {
         raffleInfo = await raffleContract.read.getRaffleInfo([BigInt(i)]) as RaffleInfo;
         console.log(`Raffle ${i} info:`, raffleInfo);
      } catch (error) {
         console.error(`Error fetching raffle info for raffle ${i}:`, error);
         continue; // Skip this raffle if fetching info fails
      }

      // Skip if raffleInfo is undefined or if the owner field is missing/null
      if (!raffleInfo || !raffleInfo.owner) {
        console.log(`Skipping raffle ${i} due to missing or invalid owner info in raffleInfo`);
        continue;
      }

      try {
        if (raffleInfo.owner.toLowerCase() === userAddress.toLowerCase()) {
          console.log(`Found created raffle ${i}`);
          const ticketsSold = Number(raffleInfo.totalTicketsSold ?? BigInt(0));
          const maxTickets = Number(raffleInfo.ticketCount ?? BigInt(0));
          const raffleState = RaffleStateMapping[raffleInfo.state ?? 0];
          console.log(`Raffle ${i} stats:`, { ticketsSold, maxTickets, raffleState });

          let nftMetadata: any = {};
          let imageUrl = '/placeholder.svg';
          let nftName = `Raffle #${i}`;
          let nftCollection = 'N/A';

          // Fetch NFT metadata only if nftAddress and tokenId are available
          if (raffleInfo.nftAddress && raffleInfo.tokenId !== undefined && raffleInfo.tokenId !== null) {
            try {
               const nftContract = getContract({
                  address: raffleInfo.nftAddress as `0x${string}`,
                  abi: ERC721ABI as any,
                  client: publicClient
               });

               if (nftContract.read && (nftContract.read as any).tokenURI) {
                 const tokenURI = await (nftContract.read as any).tokenURI([raffleInfo.tokenId]);
                 if (tokenURI) {
                     const metadataResponse = await fetch(ipfsToGatewayUrl(tokenURI as string));
                     if (metadataResponse.ok) {
                         nftMetadata = await metadataResponse.json();
                         imageUrl = ipfsToGatewayUrl(nftMetadata.image);
                         nftName = nftMetadata.name || nftName;
                         nftCollection = nftMetadata.collection || nftCollection;
                     }
                 }
               }
            } catch (nftError) {
               console.error(`Error fetching NFT metadata for raffle ${i}:`, nftError);
            }
          }

          createdRafflesDetails.push({
            id: i.toString(),
            name: nftName,
            collection: nftCollection,
            image: imageUrl,
            ticketsSold: ticketsSold,
            maxTickets: maxTickets,
            status: raffleState,
            ticketPrice: (raffleInfo.ticketPrice ?? BigInt(0)).toString(),
            endTime: Number(raffleInfo.endTime ?? BigInt(0)) * 1000,
            totalPrize: (raffleInfo.totalPrize ?? BigInt(0)).toString()
          });
        }
      } catch (error) {
        console.error(`Error processing raffle ${i}:`, error);
        // Continue processing other raffles even if one fails
        continue;
      }
    }

    return NextResponse.json(createdRafflesDetails);

  } catch (error: any) {
    console.error("Error fetching created raffles from contract:", error);
    return NextResponse.json({ error: error.message || 'Failed to fetch created raffles from contract.' }, { status: 500 });
  }
} 