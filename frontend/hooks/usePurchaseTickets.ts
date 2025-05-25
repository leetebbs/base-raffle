import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import raffleAbi from '@/lib/raffleAbi.json'; // Assuming your ABI is here

const RAFFLE_ADDRESS = "0x51FCeE5CA43fbBad5233AcDf9337B0F871DA9B15"; // Your raffle contract address

export function usePurchaseTickets() {
  // useWriteContract prepares and sends the transaction
  const { writeContract, data: hash, isPending: isPurchasePending, error: purchaseError } = useWriteContract();

  // useWaitForTransactionReceipt waits for the transaction to be mined
  const { isLoading: isConfirming, isSuccess: isConfirmed, error: confirmationError } = useWaitForTransactionReceipt({
    hash,
  });

  const purchaseTickets = (raffleId: bigint, numberOfTickets: number, ticketPrice: bigint) => {
    if (!writeContract) {
      // Wallet not connected or other issue
      console.error("Wallet not connected or cannot write contract");
      return;
    }

    const totalCost = ticketPrice * BigInt(numberOfTickets);

    console.log("Calculated total cost (Wei):", totalCost);

    writeContract({
      address: RAFFLE_ADDRESS,
      abi: raffleAbi as any, // Cast to any for now, proper type comes from wagmi/core
      functionName: 'purchaseTickets',
      args: [raffleId, BigInt(numberOfTickets)],
      value: totalCost, // Send the required ETH as value
    });
  };

  return {
    purchaseTickets,
    isLoading: isPurchasePending || isConfirming,
    isSuccess: isConfirmed,
    error: purchaseError || confirmationError,
  };
}
