import { createPublicClient, http } from "viem";
import type { Address } from "viem";
import { baseSepolia } from "viem/chains";
import erc721Abi from "@/lib/erc721Abi.json";

const fetchImageUrl = async (nftAddress: Address, tokenId: bigint) => {
  const client = createPublicClient({
    chain: baseSepolia,
    transport: http(),
  });
  const tokenURI = await client.readContract({
    address: nftAddress,
    abi: erc721Abi,
    functionName: "tokenURI",
    args: [tokenId],
  }) as string;

  let metadataUrl = tokenURI;
  if (metadataUrl.startsWith("ipfs://")) {
    metadataUrl = metadataUrl.replace("ipfs://", "https://ipfs.io/ipfs/");
  }
  const metadata = await fetch(metadataUrl).then(res => res.json());
  
  let imageUrl = metadata.image;
  // Convert ipfs:// URLs in the image URL itself
  if (imageUrl && imageUrl.startsWith("ipfs://")) {
    imageUrl = imageUrl.replace("ipfs://", "https://ipfs.io/ipfs/");
  }
  
  return imageUrl; // Return the potentially converted image URL
};

export default fetchImageUrl;