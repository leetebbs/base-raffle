import { NextRequest, NextResponse } from "next/server";
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";
import raffleAbi from "@/lib/raffleAbi.json";
import erc721Abi from "@/lib/erc721Abi.json";
import { baseSepoliaContractAddress } from "../../../config"

const RAFFLE_ADDRESS = baseSepoliaContractAddress;

type Raffle = {
  state: number;
  // ...other fields
};

function replacer(key: string, value: any) {
  return typeof value === "bigint" ? value.toString() : value;
}

export async function GET(req: NextRequest) {
  const client = createPublicClient({
    chain: baseSepolia,
    transport: http(),
  });

  // Fetch the total number of raffles
  const raffleCount = await client.readContract({
    address: baseSepoliaContractAddress as `0x${string}`,
    abi: raffleAbi,
    functionName: "raffleCounter",
  });

  // Fetch all raffles (or only the latest N for performance)
  const raffles = [];
  for (let i = 0; i < Number(raffleCount); i++) {
    const raffle = await client.readContract({
      address: baseSepoliaContractAddress as `0x${string}`,
      abi: raffleAbi,
      functionName: "getRaffleInfo",
      args: [BigInt(i)],
    }) as any;
    // Only include active raffles (state === 0 for OPEN)
    if (raffle.state === 0) {
      let image = null;
      try {
        // 1. Get tokenURI from the NFT contract
        const tokenURI = await client.readContract({
          address: raffle.nftAddress,
          abi: erc721Abi,
          functionName: "tokenURI",
          args: [raffle.tokenId],
        }) as string;

        // 2. Fetch metadata from tokenURI (handle ipfs:// links)
        let metadataUrl = tokenURI;
        if (metadataUrl.startsWith("ipfs://")) {
          metadataUrl = metadataUrl.replace("ipfs://", "https://ipfs.io/ipfs/");
        }
        const metadata = await fetch(metadataUrl).then(res => res.json());

        // 3. Get image URL (handle ipfs:// links)
        image = metadata.image;
        if (image && image.startsWith("ipfs://")) {
          image = image.replace("ipfs://", "https://ipfs.io/ipfs/");
        }
      } catch (e) {
        // If any step fails, fallback to null or a placeholder
        image = null;
      }

      raffles.push({ ...raffle, id: i, image });
    }
  }

  return new NextResponse(JSON.stringify(raffles, replacer), {
    headers: { "Content-Type": "application/json" }
  });
}
