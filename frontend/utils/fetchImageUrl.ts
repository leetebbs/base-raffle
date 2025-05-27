import { createPublicClient, http } from 'viem';
import { baseSepolia } from 'viem/chains';
import { erc721Abi } from 'viem';

export async function fetchImageUrl(nftAddress: string, tokenId: string): Promise<string> {
  try {
    // Initialize the Viem client
    const client = createPublicClient({
      chain: baseSepolia,
      transport: http()
    });

    // Get the tokenURI from the NFT contract
    const tokenURI = await client.readContract({
      address: nftAddress as `0x${string}`,
      abi: erc721Abi,
      functionName: 'tokenURI',
      args: [BigInt(tokenId)],
    });

    if (!tokenURI) {
      throw new Error('No tokenURI found');
    }

    // Handle IPFS URLs
    let metadataUrl = tokenURI as string;
    if (metadataUrl.startsWith('ipfs://')) {
      metadataUrl = `https://ipfs.io/ipfs/${metadataUrl.replace('ipfs://', '')}`;
    }

    // Fetch the metadata
    const response = await fetch(metadataUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch metadata: ${response.statusText}`);
    }

    const metadata = await response.json();
    
    // Handle IPFS image URLs
    let imageUrl = metadata.image;
    if (imageUrl.startsWith('ipfs://')) {
      imageUrl = `https://ipfs.io/ipfs/${imageUrl.replace('ipfs://', '')}`;
    }

    return imageUrl;
  } catch (error) {
    console.error('Error fetching image URL:', error);
    return '/placeholder-nft.png';
  }
} 