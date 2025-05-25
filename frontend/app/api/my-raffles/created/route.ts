import { NextResponse } from 'next/server';
import { createPublicClient, http, getContract } from 'viem';
import { baseSepolia } from 'viem/chains';
import RaffleABI from '@/lib/raffleAbi.json'; // Corrected ABI import
import ERC721ABI from '@/lib/erc721Abi.json'; // Assuming you have a minimal ERC721 ABI with tokenURI here

const raffleContractAddress = '0x51FCeE5CA43fbBad5233AcDf9337B0F871DA9B15'; // Replace with your contract address

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http()
});

// Define RaffleInfo type based on your contract struct
type RaffleInfo = readonly [
  string, // nftAddress
  bigint, // tokenId
  string, // owner
  bigint, // ticketCount (max tickets)
  bigint, // ticketPrice
  bigint, // startTime
  bigint, // endTime
  bigint, // totalTicketsSold
  bigint, // totalPrize
  bigint, // numberOfTicketsToBeSoldForRaffleToExecute
  number, // state (enum uint8)
  string, // winner
  bigint  // requestId
];

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
      address: raffleContractAddress,
      abi: RaffleABI as any, // Casting to any for compatibility, ideally use 'as const'
      client: publicClient
    });

    const raffleCounter = await raffleContract.read.raffleCounter([]);
    const totalRaffles = Number(raffleCounter);

    const createdRafflesDetails: any[] = [];

    // Iterate through all raffles to find those the user has created
    for (let i = 0; i < totalRaffles; i++) {
      const raffleInfo = await raffleContract.read.getRaffleInfo([BigInt(i)]) as RaffleInfo;

      if (raffleInfo && typeof raffleInfo[2] === "string" && raffleInfo[2].toLowerCase() === userAddress.toLowerCase()) {
         const ticketsSold = Number(raffleInfo[7]); // totalTicketsSold is index 7
         const maxTickets = Number(raffleInfo[3]); // ticketCount is index 3
         const raffleState = RaffleStateMapping[raffleInfo[10]]; // state is index 10

         let nftMetadata: any = {};
         let imageUrl = '/placeholder.svg';
         let nftName = `Raffle #${i}`;
         let nftCollection = 'N/A';

         try {
            // Fetch NFT metadata
            const nftContract = getContract({
               address: raffleInfo[0] as `0x${string}`,
               abi: ERC721ABI as any, // Casting to any for compatibility, ideally use 'as const'
               client: publicClient
            });

            // Check if the NFT contract has a tokenURI function (basic check)
           if (nftContract.read && (nftContract.read as any).tokenURI) {
             const tokenURI = await (nftContract.read as any).tokenURI([raffleInfo[1]]);
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
            // Continue without NFT metadata if fetching fails
         }

        createdRafflesDetails.push({
          id: i.toString(),
          name: nftName, // Use fetched NFT name or default
          collection: nftCollection, // Use fetched NFT collection or default
          image: imageUrl, // Use fetched image URL or default
          ticketsSold: ticketsSold,
          maxTickets: maxTickets,
          status: raffleState,
          ticketPrice: raffleInfo[4].toString(), // ticketPrice is index 4
          endTime: Number(raffleInfo[6]) * 1000, // endTime is index 6, convert to milliseconds
        });
      }
    }

    return NextResponse.json(createdRafflesDetails);

  } catch (error: any) {
    console.error("Error fetching created raffles from contract:", error);
    return NextResponse.json({ error: error.message || 'Failed to fetch created raffles from contract.' }, { status: 500 });
  }
} 