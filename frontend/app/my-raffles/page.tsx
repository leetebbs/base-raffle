"use client";

import React, { useState, useEffect } from "react";
import { useAccount } from 'wagmi';
import { formatEther } from "viem";
import Image from "next/image";
import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

// Helper function to convert IPFS URL to a gateway URL
const ipfsToGatewayUrl = (ipfsUrl: string) => {
  if (!ipfsUrl) return "/placeholder.svg";
  if (ipfsUrl.startsWith("ipfs://")) {
    const cid = ipfsUrl.replace("ipfs://", "");
    return `https://ipfs.io/ipfs/${cid}`;
  }
  // Return the original URL if it's not an IPFS URL
  return ipfsUrl;
};

export default function MyRafflesPage() {
  const { address, isConnected } = useAccount();
  const [enteredRaffles, setEnteredRaffles] = useState<any[]>([]);
  const [isLoadingRaffles, setIsLoadingRaffles] = useState(false);
  const [errorFetching, setErrorFetching] = useState<string | null>(null);

  const [createdRaffles, setCreatedRaffles] = useState<any[]>([]);
  const [isLoadingCreatedRaffles, setIsLoadingCreatedRaffles] = useState(false);
  const [errorFetchingCreated, setErrorFetchingCreated] = useState<string | null>(null);

  useEffect(() => {
    if (isConnected && address) {
      setIsLoadingRaffles(true);
      setErrorFetching(null);
      console.log("Fetching entered raffles for address:", address);
      fetch(`/api/my-raffles/entered?address=${address}`)
        .then(res => {
          if (!res.ok) {
            console.error(`API Error (Entered): ${res.status} - ${res.statusText}`);
            return res.text().then(text => { throw new Error(`API error (Entered): ${res.status} - ${text}`); });
          }
          return res.json();
        })
        .then(data => {
          console.log("returned Raffles created" , data)
          setEnteredRaffles(data);
          setIsLoadingRaffles(false);
        })
        .catch(error => {
          console.error("Error fetching entered raffles:", error);
          setErrorFetching(error.message || "Failed to fetch entered raffles.");
          setIsLoadingRaffles(false);
        });

      setIsLoadingCreatedRaffles(true);
      setErrorFetchingCreated(null);
      console.log("Fetching created raffles for address:", address);
      fetch(`/api/my-raffles/created?address=${address}`)
        .then(res => {
           if (!res.ok) {
            console.error(`API Error (Created): ${res.status} - ${res.statusText}`);
            return res.text().then(text => { throw new Error(`API error (Created): ${res.status} - ${text}`); });
          }
          return res.json();
        })
        .then(data => {
          setCreatedRaffles(data);
          setIsLoadingCreatedRaffles(false);
        })
        .catch(error => {
          console.error("Error fetching created raffles:", error);
          setErrorFetchingCreated(error.message || "Failed to fetch created raffles.");
          setIsLoadingCreatedRaffles(false);
        });

    } else {
      setEnteredRaffles([]);
      setErrorFetching(null);
      setCreatedRaffles([]);
      setErrorFetchingCreated(null);
    }
  }, [isConnected, address]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
      <div className="container mx-auto px-4">
        <h1 className="text-2xl font-bold text-white mb-8">My Raffles</h1>
        
        {/* Section for Entered Raffles */}
        <div className="mb-12">
          <h2 className="text-xl font-semibold text-white mb-4">Raffles Entered</h2>
          {!isConnected ? (
            <p className="text-slate-300">Connect your wallet to see your entered raffles.</p>
          ) : isLoadingRaffles ? (
            <p className="text-slate-300">Loading entered raffles...</p>
          ) : errorFetching ? (
            <p className="text-red-400">Error: {errorFetching}</p>
          ) : enteredRaffles.length === 0 ? (
            <p className="text-slate-300">No raffles entered yet.</p>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-6">
              {enteredRaffles.map(raffle => (
                 <Card key={raffle.id} className="overflow-hidden bg-slate-800/50 backdrop-blur-sm">
                   <Link href={`/raffle/${raffle.id}`} passHref>
                     <div className="relative aspect-square w-full">
                       <Image
                         src={ipfsToGatewayUrl(raffle.image)}
                         alt={raffle.name || "Raffle NFT"}
                         fill
                         className="object-cover"
                       />
                     </div>
                     <CardContent className="p-4">
                       <h3 className="text-lg font-semibold text-white mb-1 truncate">{raffle.name}</h3>
                       <p className="text-sm text-slate-400 mb-2 truncate">{raffle.collection || "N/A"}</p>
                       <div className="flex items-center justify-between text-slate-300 text-sm">
                         <span>Tickets purchased:</span>
                         <span className="font-medium text-white">{raffle.userTicketsCount || "N/A"}</span>
                       </div>
                        <div className="flex items-center justify-between text-slate-300 text-sm mt-1">
                         <span>Ticket price:</span>
                         <span className="font-medium text-white">{raffle.ticketPrice ? `${formatEther(BigInt(raffle.ticketPrice))} ETH` : "N/A"}</span>
                       </div>
                     </CardContent>
                   </Link>
                 </Card>
              ))}
            </div>
          )}
        </div>

        {/* Section for Created Raffles */}
        <div>
          <h2 className="text-xl font-semibold text-white mb-4">Raffles Created</h2>
          {!isConnected ? (
             <p className="text-slate-300">Connect your wallet to see your created raffles.</p>
          ) : isLoadingCreatedRaffles ? (
            <p className="text-slate-300">Loading created raffles...</p>
          ) : errorFetchingCreated ? (
            <p className="text-red-400">Error: {errorFetchingCreated}</p>
          ) : createdRaffles.length === 0 ? (
             <p className="text-slate-300">No raffles created yet.</p>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-6">
              {createdRaffles.map(raffle => (
                 <Card key={raffle.id} className="overflow-hidden bg-slate-800/50 backdrop-blur-sm">
                   <Link href={`/raffle/${raffle.id}`} passHref>
                     <div className="relative aspect-square w-full">
                       <Image
                         src={ipfsToGatewayUrl(raffle.image)}
                         alt={raffle.name || "Raffle NFT"}
                         fill
                         className="object-cover"
                       />
                     </div>
                     <CardContent className="p-4">
                       <h3 className="text-lg font-semibold text-white mb-1 truncate">{raffle.name}</h3>
                       <p className="text-sm text-slate-400 mb-2 truncate">{raffle.collection || "N/A"}</p>
                       <div className="flex items-center justify-between text-slate-300 text-sm">
                         <span>Tickets sold:</span>
                         <span className="font-medium text-white">{raffle.ticketsSold || "N/A"} / {raffle.maxTickets || "N/A"}</span>
                       </div>
                        <div className="flex items-center justify-between text-slate-300 text-sm mt-1">
                         <span>Status:</span>
                         <span className="font-medium text-white">{raffle.status || "N/A"}</span>
                       </div>
                     </CardContent>
                   </Link>
                 </Card>
              ))}
            </div>
          )}
        </div>

      </div>
    </div>
  );
} 