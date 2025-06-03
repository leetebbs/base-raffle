import { NextRequest, NextResponse } from "next/server";
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import raffleAbi from "@/lib/raffleAbi.json";
import fetchImageUrl from "@/components/fetchImageUrl";
import erc721Abi from "@/lib/erc721Abi.json";
import { baseSepoliaContractAddress } from "@/config";

const RAFFLE_ADDRESS = baseSepoliaContractAddress;

type Raffle = { // Assuming you have this type defined or similar
  state: number;
  nftAddress: string; // Add other expected fields
  tokenId: bigint;
  owner: string;
  ticketCount: bigint;
  ticketPrice: bigint;
  startTime: bigint;
  endTime: bigint;
  totalTicketsSold: bigint;
  totalPrize: bigint;
  numberOfTicketsToBeSoldForRaffleToExecute: bigint;
  winner: string;
  requestId: bigint;
  image?: string; // Add image property
};

// --- FIX: Helper function to serialize BigInt ---
function replacer(key: string, value: any) {
  return typeof value === "bigint" ? value.toString() : value;
}
// ---------------------------------------------

export async function GET(request: Request) {
  const url = new URL(request.url);
  const id = url.pathname.split('/').pop();
  if (!id) {
    return NextResponse.json({ error: "No raffle id provided in URL." }, { status: 400 });
  }

  const client = createPublicClient({
    chain: baseSepolia,
    transport: http(),
  });

  try {
    const info = await client.readContract({
      address: RAFFLE_ADDRESS as `0x${string}`,
      abi: raffleAbi,
      functionName: "getRaffleInfo",
      args: [BigInt(id)],
    }) as Raffle; // Keep type assertion if you have the type defined

    // Check if the raffle is canceled (state 5)
    console.log("Raffle info state:", info.state);
    if (info.state === 3) {
      return NextResponse.json({ error: "Raffle has been canceled." }, { status: 404 });
    }

    // Fetch raffle participants
    const participants = await client.readContract({
      address: RAFFLE_ADDRESS as `0x${string}`,
      abi: raffleAbi, // Ensure raffleAbi includes the raffleParticipants definition
      functionName: "getRaffleParticipants",
      args: [BigInt(id)],
    }) as string[]; // Assuming it returns an array of addresses

    let nftName = "N/A";
    let collectionName = "N/A";
    let creatorName = "N/A"; // Initialize creatorName

    // Fetch NFT metadata to get name, collection, and creator
    try {
      // 1. Get tokenURI from the NFT contract
      const tokenURI = await client.readContract({
        address: info.nftAddress as `0x${string}`,
        abi: erc721Abi,
        functionName: "tokenURI",
        args: [info.tokenId],
      }) as string;

      // 2. Fetch metadata from tokenURI (handle ipfs:// links)
      let metadataUrl = tokenURI;
      if (metadataUrl.startsWith("ipfs://")) {
        metadataUrl = metadataUrl.replace("ipfs://", "https://ipfs.io/ipfs/");
      }
      const metadata = await fetch(metadataUrl).then(res => res.json());

      // 3. Extract name, collection, and creator
      nftName = metadata.name || "N/A";
      collectionName = metadata.collection || metadata.contract?.name || "N/A";
      creatorName = metadata.creator || metadata.artist || metadata.owner || "N/A"; // Attempt to extract creator from common fields

      // 4. Get image URL (handle ipfs:// links) - Keep existing image fetching logic
      let imageUrl = metadata.image;
      if (imageUrl && imageUrl.startsWith("ipfs://")) {
        imageUrl = imageUrl.replace("ipfs://", "https://ipfs.io/ipfs/");
      }
      info.image = imageUrl; // Assign fetched image URL

    } catch (metadataError) {
      console.error("Error fetching NFT metadata:", metadataError);
      // Fallback values are already set to "N/A"
    }

    // Convert bigint timestamps to strings or numbers for JSON serialization
    // And ensure endTime is a valid format for the frontend new Date() conversion
    const serializedInfo = {
      ...info,
      id: id,
      tokenId: info.tokenId.toString(),
      ticketCount: info.ticketCount.toString(),
      ticketPrice: info.ticketPrice.toString(),
      startTime: info.startTime.toString(),
      endTime: Number(info.endTime) * 1000,
      totalTicketsSold: info.totalTicketsSold.toString(),
      totalPrize: info.totalPrize.toString(),
      numberOfTicketsToBeSoldForRaffleToExecute: info.numberOfTicketsToBeSoldForRaffleToExecute.toString(),
      requestId: info.requestId.toString(),
      participants: participants,
      name: nftName,
      collection: collectionName,
      creator: creatorName, // Add creator name to the response
      // image is already handled
    };

    // --- FIX: Manually stringify with replacer ---
    return new NextResponse(JSON.stringify(serializedInfo, replacer), {
      headers: { "Content-Type": "application/json" }
    });
    // --------------------------------------------
  } catch (error: any) {
    console.error("Error in /api/raffle/[id] route:", error);
    // Still return a 500 with error message for debugging on the frontend
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}