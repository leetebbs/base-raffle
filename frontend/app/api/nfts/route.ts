import { Alchemy, Network } from 'alchemy-sdk';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const address = searchParams.get('address');
    const chainId = searchParams.get('chainId');

    if (!address || !chainId) {
      return NextResponse.json({ error: 'Missing address or chainId' }, { status: 400 });
    }

    // Map chain ID to Alchemy Network enum (you might need a more comprehensive mapping)
    let network;
    switch (parseInt(chainId)) {
      case 1: // Ethereum Mainnet
        network = Network.ETH_MAINNET;
        break;
      case 11155111: // Sepolia
        network = Network.ETH_SEPOLIA;
        break;
      case 84532: // Base Sepolia
        network = Network.BASE_SEPOLIA;
        break;
      // Add other networks as needed
      default:
        return NextResponse.json({ error: `Unsupported chain ID: ${chainId}` }, { status: 400 });
    }

    const config = {
      apiKey: process.env.ALCHEMY_API_KEY, // Make sure your API key is in your environment variables
      network: network,
    };

    const alchemy = new Alchemy(config);

    const nfts = await alchemy.nft.getNftsForOwner(address, { pageSize: 10 });
    console.log(nfts);
    return NextResponse.json(nfts);
  } catch (error) {
    console.error('Error fetching NFTs in API route:', error);
    return NextResponse.json({ error: 'Failed to fetch NFTs' }, { status: 500 });
  }
} 