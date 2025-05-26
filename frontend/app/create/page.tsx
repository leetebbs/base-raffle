"use client"

import type React from "react"

import { useState, useEffect } from "react"
import Image from "next/image"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { WalletConnect } from "@/components/wallet-connect"
import { ArrowLeft, Info } from "lucide-react"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { useAccount } from "wagmi"
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem'; // To convert ETH string to Wei BigInt
import raffleAbi from '@/lib/raffleAbi.json'; // Import your contract ABI
import { baseSepoliaContractAddress } from "@/config"

// Minimal ABI for ERC721 approve function
const erc721Abi = [
  {
    "inputs": [
      { "internalType": "address", "name": "to", "type": "address" },
      { "internalType": "uint256", "name": "tokenId", "type": "uint256" }
    ],
    "name": "approve",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

// Deployed Raffle Contract Address on Base Sepolia
const RAFFLE_CONTRACT_ADDRESS = baseSepoliaContractAddress;

export default function CreateRafflePage() {
  const [selectedNft, setSelectedNft] = useState<number | null>(null)
  const [ticketPrice, setTicketPrice] = useState("0.05")
  const [maxTickets, setMaxTickets] = useState("100")
  const [duration, setDuration] = useState("3")
  const [fetchedNfts, setFetchedNfts] = useState<any[] | null>(null)
  const [minTicketsRequired, setMinTicketsRequired] = useState("10")
  const [isNftApproved, setIsNftApproved] = useState(false);

  const { isConnected, address, chain } = useAccount()

  useEffect(() => {
    const fetchNfts = async () => {
      if (isConnected && address && chain?.id) {
        try {
          console.log("Fetching NFTs for address:", address);
          console.log("Connected chain ID:", chain.id);
          console.log("Connected chain name:", chain.name);

          // TODO: Implement NFT fetching using Alchemy SDK or a Next.js API route
          // Example using a hypothetical fetch function (replace with actual Alchemy SDK call or API fetch):
          // const response = await fetch(`/api/nfts?address=${address}&network=eth-mainnet&pageSize=10`);
          // const data = await response.json();
          // if (data && data.nfts) {
          //   setFetchedNfts(data.nfts);
          // } else {
          //   setFetchedNfts([]);
          // }

          // TODO: Replace with your actual Alchemy SDK initialization
          // Make sure to configure the network and API key correctly
          // import { Alchemy, Network } from "alchemy-sdk";
          // const config = {
          //   apiKey: process.env.NEXT_PUBLIC_ALCHEMY_API_KEY, // Replace with your env variable name
          //   network: chain.id, // Alchemy SDK can often use chain ID directly
          //   // Or map chain.id to Alchemy's network string if needed:
          //   // network: chain.id === 84532 ? "base-sepolia" : "", // Example mapping for Base Sepolia
          // };
          // const alchemy = new Alchemy(config);

          // // Replace with the actual SDK call, using the connected chain's ID or a mapped network name
          // // The exact method might vary based on your Alchemy SDK version and configuration.
          // const nfts = await alchemy.nft.getNftsForOwner(address, {
          //   chain: chain.id, // Use the connected chain's ID
          //   pageSize: 10,
          // });

          // // Assuming the response structure includes a 'ownedNfts' array
          // if (nfts && nfts.ownedNfts) {
          //   setFetchedNfts(nfts.ownedNfts);
          // } else {
          //   setFetchedNfts([]); // Set to empty array if no NFTs or unexpected response
          // }

          // Call the new API route to fetch NFTs
          const response = await fetch(`/api/nfts?address=${address}&chainId=${chain.id}`);
          
          if (!response.ok) {
            throw new Error(`Error fetching NFTs: ${response.statusText}`);
          }
          
          const data = await response.json();

          // Assuming the API route returns an object with an 'ownedNfts' array
          if (data && data.ownedNfts) {
            setFetchedNfts(data.ownedNfts);
          } else {
            setFetchedNfts([]); // Set to empty array if no NFTs or unexpected response
          }

        } catch (error: any) {
          console.error("Error fetching NFTs:", error);
          setFetchedNfts([]);
        }
      }
    };

    fetchNfts();
  }, [isConnected, address, chain]); // Dependencies: re-run when connection status or address changes

  const handleNftSelect = (index: number) => {
    setSelectedNft(index)
  }

  // Function to transform IPFS URLs using a gateway
  const resolveIpfsUrl = (ipfsUrl: string | undefined) => {
    if (!ipfsUrl) return undefined; // Return undefined if no URL or empty string
    if (typeof ipfsUrl === 'string' && ipfsUrl.startsWith("ipfs://")) {
      const hash = ipfsUrl.replace("ipfs://", "");
      return `https://ipfs.io/ipfs/${hash}`;
    }
    return ipfsUrl; // Return the original URL if it's not IPFS
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (selectedNft === null || !fetchedNfts) {
      alert("Please select an NFT.");
      return;
    }

    const nft = fetchedNfts[selectedNft];
    console.log("Selected NFT object:", nft);
    if (!nft || !nft.contract?.address || !nft.tokenId) {
        alert("Selected NFT data is incomplete.");
        return;
    }

    try {
        const nftAddress = nft.contract.address;
        const tokenId = BigInt(nft.tokenId); // Use nft.tokenId
        const raffleTicketCount = BigInt(maxTickets); // maxTickets corresponds to ticketCount in contract
        const raffleTicketPrice = parseEther(ticketPrice); // Convert ETH string to Wei BigInt
        const raffleLengthInSeconds = BigInt(Number(duration) * 24 * 60 * 60); // Convert days to seconds, then to BigInt
        const requiredMinTickets = BigInt(minTicketsRequired); // minTicketsRequired corresponds to minTicketsRequired in contract

        console.log("Arguments being sent to writeContract:", [
          nftAddress,
          tokenId,
          raffleTicketCount,
          raffleTicketPrice,
          raffleLengthInSeconds,
          requiredMinTickets
        ]);

        // Use the writeContract function provided by the wagmi hook
        await writeContract({
            address: baseSepoliaContractAddress as `0x${string}`, // Your deployed contract address
            abi: raffleAbi, // Your contract ABI
            functionName: 'createRaffle',
            args: [
                nftAddress,
                tokenId,
                raffleTicketCount,
                raffleTicketPrice,
                raffleLengthInSeconds,
                requiredMinTickets
            ],
        });

        // The rest of the transaction handling (waiting for receipt) is done by useWaitForTransactionReceipt

    } catch (error: any) {
        console.error("Error creating raffle:", error);
        // alert(`Error creating raffle: ${error.message || error}`);
    }
  }

  // Get the write function and state from the wagmi hook for Raffle creation
  const { data: hash, writeContract, isPending: isWritePending, error: writeError } = useWriteContract();

  // Get the write function and state from the wagmi hook for NFT approval
  const { data: approvalHash, writeContract: approveNft, isPending: isApprovalPending, error: approvalError } = useWriteContract();

  // Wait for the raffle creation transaction to be confirmed
  const { isLoading: isConfirming, isSuccess: isConfirmed, error: confirmError } = useWaitForTransactionReceipt({
    hash,
  });

  // Wait for the NFT approval transaction to be confirmed
  const { isLoading: isApprovalConfirming, isSuccess: isApprovalConfirmed, error: approvalConfirmError } = useWaitForTransactionReceipt({
    hash: approvalHash,
  });

  // Handle approval success
  useEffect(() => {
    if (isApprovalConfirmed) {
      setIsNftApproved(true);
      alert("NFT approved successfully!");
    }
    if (approvalError || approvalConfirmError) {
      const error = approvalError ?? approvalConfirmError;
      alert(`NFT Approval failed: ${error?.message || error}`);
    }
  }, [isApprovalConfirmed, approvalError, approvalConfirmError]);

  // Provide feedback to the user for Raffle Creation
  useEffect(() => {
      if (isConfirmed) {
          alert("Raffle created successfully!");
          // Optional: Redirect or clear form
      }
      if (writeError || confirmError) {
          const error = writeError ?? confirmError;
          alert(`Transaction failed: ${error?.message || error}`);
      }
  }, [isConfirmed, writeError, confirmError]);

  const handleApproveNft = async () => {
    if (selectedNft === null || !fetchedNfts) {
        alert("Please select an NFT to approve.");
        return;
    }

    const nft = fetchedNfts[selectedNft];
    if (!nft || !nft.contract?.address || !nft.tokenId) {
        alert("Selected NFT data is incomplete.");
        return;
    }

    try {
        await approveNft({
            address: nft.contract.address, // NFT contract address
            abi: erc721Abi, // ERC721 ABI with approve function
            functionName: 'approve',
            args: [baseSepoliaContractAddress, BigInt(nft.tokenId)], // Approve the raffle contract for the specific token ID
        });
    } catch (error: any) {
         console.error("Error approving NFT:", error);
        // alert(`Error approving NFT: ${error.message || error}`);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
      <div className="container mx-auto px-4">
        <Link href="/" className="mb-8 inline-flex items-center text-purple-400 hover:text-purple-300">
          <ArrowLeft className="mr-2 h-4 w-4" /> Back to home
        </Link>

        <h1 className="mb-8 text-3xl font-bold text-white md:text-4xl">Create a Raffle</h1>

        {!isConnected ? (
          <div className="mx-auto max-w-md rounded-xl bg-slate-800/50 p-8 text-center backdrop-blur-sm">
            <h2 className="mb-6 text-xl font-semibold text-white">Connect Your Wallet</h2>
            <p className="mb-6 text-slate-300">Connect your wallet to access your NFTs and create a raffle.</p>
            <WalletConnect />
          </div>
        ) : (
          <div className="grid gap-8 lg:grid-cols-3">
            <div className="lg:col-span-2">
              <div className="mb-8 rounded-xl bg-slate-800/50 p-6 backdrop-blur-sm">
                <h2 className="mb-4 text-xl font-semibold text-white">Select an NFT to Raffle</h2>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-2 xl:grid-cols-3">
                  {fetchedNfts?.map((nft, index) => {
                    // Prioritize media gateway, then image object URLs
                    const imageUrl = nft.media?.[0]?.gateway || nft.image?.cachedUrl || nft.image?.originalUrl;
                    const imgSrc = resolveIpfsUrl(imageUrl);
                    // Use nft.id as key if available, fallback to index
                    const itemKey = nft?.id ?? index;

                    return (
                      <Card
                        key={itemKey} // Use itemKey which falls back to index
                        className={`cursor-pointer overflow-hidden bg-slate-700/50 transition-all hover:ring-2 hover:ring-purple-500 ${ selectedNft === index ? "ring-2 ring-purple-500" : "" }`}
                        onClick={() => handleNftSelect(index)}
                      >
                        <div className="relative aspect-square">
                          {/* Conditionally render Image only if src is a valid non-empty string */}
                          {typeof imgSrc === 'string' && imgSrc !== '' && (
                            <Image
                              src={imgSrc}
                              alt={nft.name || "NFT Image"}
                              fill
                              sizes="(max-width: 640px) 100vw, (max-width: 768px) 50vw, 33vw"
                              className="object-cover"
                            />
                          )}
                        </div>
                        <CardContent className="p-3">
                          <h3 className="font-medium text-white">{nft.title || "Unknown NFT"}</h3>
                          <p className="text-sm text-slate-400">{nft.collection?.name || "Unknown Collection"}</p>
                        </CardContent>
                      </Card>
                    );
                  })}
                </div>
              </div>

              {/* NFT Approval Section */}
              {selectedNft !== null && !isNftApproved && (
                <div className="mb-8 rounded-xl bg-yellow-800/50 p-6 backdrop-blur-sm text-yellow-100">
                  <h2 className="mb-4 text-xl font-semibold">Approve Your NFT</h2>
                  <p className="mb-4">Before launching the raffle, you need to approve the raffle contract to transfer your selected NFT.</p>
                  <Button
                    onClick={handleApproveNft}
                    disabled={isApprovalPending || isApprovalConfirming}
                    className="w-full bg-yellow-600 hover:bg-yellow-700 text-white py-6 text-lg font-semibold"
                  >
                    {isApprovalPending ? 'Confirm Approval in wallet...' : isApprovalConfirming ? 'Approving...' : 'Approve NFT'}
                  </Button>
                </div>
              )}

              {/* Raffle Details Form */}
              {selectedNft !== null && isNftApproved && (
                <form onSubmit={handleSubmit} className="rounded-xl bg-slate-800/50 p-6 backdrop-blur-sm">
                  <h2 className="mb-6 text-xl font-semibold text-white">Raffle Details</h2>

                  <div className="mb-6 grid gap-6 md:grid-cols-2">
                    <div className="space-y-2">
                      <div className="flex items-center">
                        <Label htmlFor="ticketPrice" className="text-white">
                          Ticket Price (ETH)
                        </Label>
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Info className="ml-2 h-4 w-4 text-slate-400" />
                            </TooltipTrigger>
                            <TooltipContent>
                              <p>The price in ETH for each raffle ticket</p>
                            </TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                      </div>
                      <Input
                        id="ticketPrice"
                        type="number"
                        step="0.01"
                        value={ticketPrice}
                        onChange={(e) => setTicketPrice(e.target.value)}
                        className="bg-slate-700/50 text-white"
                      />
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center">
                        <Label htmlFor="maxTickets" className="text-white">
                          Maximum Tickets
                        </Label>
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Info className="ml-2 h-4 w-4 text-slate-400" />
                            </TooltipTrigger>
                            <TooltipContent>
                              <p>The maximum number of tickets available for purchase</p>
                            </TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                      </div>
                      <Input
                        id="maxTickets"
                        type="number"
                        min="10"
                        max="1000"
                        value={maxTickets}
                        onChange={(e) => setMaxTickets(e.target.value)}
                        className="bg-slate-700/50 text-white"
                      />
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center">
                        <Label htmlFor="minTicketsRequired" className="text-white">
                          Minimum Tickets Required
                        </Label>
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Info className="ml-2 h-4 w-4 text-slate-400" />
                            </TooltipTrigger>
                            <TooltipContent>
                              <p>The minimum number of tickets that must be sold for the raffle to execute.</p>
                            </TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                      </div>
                      <Input
                        id="minTicketsRequired"
                        type="number"
                        min="1"
                        value={minTicketsRequired}
                        onChange={(e) => setMinTicketsRequired(e.target.value)}
                        className="bg-slate-700/50 text-white"
                      />
                    </div>
                  </div>

                  <div className="mb-8 space-y-2">
                    <div className="flex items-center">
                      <Label htmlFor="duration" className="text-white">
                        Raffle Duration: {duration} days
                      </Label>
                      <TooltipProvider>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Info className="ml-2 h-4 w-4 text-slate-400" />
                          </TooltipTrigger>
                          <TooltipContent>
                            <p>How long the raffle will be active</p>
                          </TooltipContent>
                        </Tooltip>
                      </TooltipProvider>
                    </div>
                    <div className="px-2">
                      <Slider
                        id="duration"
                        min={1}
                        max={14}
                        step={1}
                        value={[Number.parseInt(duration)]}
                        onValueChange={(value) => setDuration(value[0].toString())}
                        className="py-4"
                      />
                      <div className="flex justify-between text-xs text-slate-400">
                        <span>1 day</span>
                        <span>7 days</span>
                        <span>14 days</span>
                      </div>
                    </div>
                  </div>

                  <Button
                    type="submit"
                    disabled={selectedNft === null || !writeContract || isWritePending || isConfirming || !isNftApproved}
                    className="w-full bg-gradient-to-r from-purple-600 to-pink-600 py-6 text-lg font-semibold"
                  >
                    {isWritePending ? 'Confirm in wallet...' : isConfirming ? 'Launching...' : 'Launch Raffle'}
                  </Button>
                </form>
              )}
            </div>

            <div className="lg:col-span-1">
              <div className="sticky top-6 rounded-xl bg-slate-800/50 p-6 backdrop-blur-sm">
                <h2 className="mb-4 text-xl font-semibold text-white">Raffle Preview</h2>

                {selectedNft !== null ? (
                  <div>
                    <div className="mb-4 overflow-hidden rounded-lg">
                      {/* Conditionally render Image only if src is a valid non-empty string */}
                      {(() => {
                        // Find the selected NFT using the stored index
                        const selectedNftData = fetchedNfts?.[selectedNft];
                        const previewImageUrl = selectedNftData?.media?.[0]?.gateway || selectedNftData?.image?.cachedUrl || selectedNftData?.image?.originalUrl;
                        const previewImgSrc = resolveIpfsUrl(previewImageUrl);

                        return typeof previewImgSrc === 'string' && previewImgSrc !== '' && (
                          <Image
                            src={previewImgSrc}
                            alt="Selected NFT"
                            width={300}
                            height={300}
                            className="h-auto w-full"
                            sizes="(max-width: 640px) 100vw, (max-width: 768px) 50vw, 33vw"
                          />
                        );
                      })()}
                    </div>
                    <h3 className="mb-1 text-lg font-medium text-white">
                      {fetchedNfts?.[selectedNft]?.title || "Unknown NFT"}
                    </h3>
                    <p className="mb-4 text-sm text-slate-400">
                      {fetchedNfts?.[selectedNft]?.collection?.name || "Unknown Collection"}
                    </p>

                    <div className="space-y-3">
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">Ticket Price:</span>
                        <span className="font-medium text-white">{ticketPrice} ETH</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">Max Tickets:</span>
                        <span className="font-medium text-white">{maxTickets}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">Duration:</span>
                        <span className="font-medium text-white">{duration} days</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">Potential Value:</span>
                        <span className="font-medium text-white">
                          {(Number.parseFloat(ticketPrice) * Number.parseInt(maxTickets))} ETH
                        </span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">Minimum Tickets:</span>
                        <span className="font-medium text-white">{minTicketsRequired}</span>
                      </div>
                    </div>

                    <div className="mt-6 rounded-lg bg-slate-700/50 p-4 text-sm text-slate-300">
                      <p>
                        Your NFT will be held in a secure escrow contract until the raffle concludes. If all tickets
                        sell out, the winner will be selected automatically.
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="rounded-lg bg-slate-700/30 p-8 text-center">
                    <p className="text-slate-400">Select an NFT to see the preview</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
