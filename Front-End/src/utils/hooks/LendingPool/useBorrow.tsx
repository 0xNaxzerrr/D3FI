import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { Abi, parseEther } from 'viem';
import LendingPoolAbi from '../../abis/LendingPool.json';
import ERC20Abi from '../../abis/ERC20.json';
import { useState } from 'react';
import { MARKETS } from '@/utils/constants/MARKETS';

/**
 * Hook pour emprunter sur une LendingPool
 * @param poolAddress Adresse du contrat LendingPool
 * @param asset Adresse de l'asset (address(0) ou 0x... pour ETH)
 * @param amount Montant à emprunter (string, en ETH ou token)
 * @returns { borrow, isApproving, isBorrowPending, approveError, borrowError }
 */
export function useBorrow({ poolAddress, asset, amount }: {
  poolAddress: `0x${string}`,
  asset: `0x${string}`,
  amount: string
}) {
  const [isApproving, setIsApproving] = useState(false);
  const [approveError, setApproveError] = useState<string | null>(null);
  const [borrowError, setBorrowError] = useState<string | null>(null);

  const { writeContract, isPending: isBorrowPending, error: borrowWriteError, data: borrowTxHash } = useWriteContract();
  const { writeContract: writeApprove, isPending: isApprovePending, error: approveWriteError } = useWriteContract();

  // Helper to check if asset is ETH
  const isETH = asset === MARKETS[0].address;

  // Approve and borrow logic
  const borrow = async () => {
    setApproveError(null);
    setBorrowError(null);
    try {
      if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) throw new Error('Montant invalide');
      const parsedAmount = parseEther(amount);
      if (!isETH) {
        // Approve first
        setIsApproving(true);
        await writeApprove({
          abi: ERC20Abi,
          address: asset,
          functionName: 'approve',
          args: [poolAddress, parsedAmount],
        });
        setIsApproving(false);
      }
      // Borrow
      writeContract({
        abi: LendingPoolAbi.abi as Abi,
        address: poolAddress,
        functionName: 'borrow',
        args: [parsedAmount],
        value: isETH ? parsedAmount : undefined,
      });
    } catch (err: any) {
      setIsApproving(false);
      setApproveError(err.message);
    }
  };

  // Wait for tx confirmation (optionnel, si besoin)
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash: borrowTxHash as `0x${string}` | undefined,
  });

  return {
    borrow,
    isApproving: isApproving || isApprovePending,
    isBorrowPending,
    isConfirming,
    isConfirmed,
    approveError,
    borrowError: borrowError || (borrowWriteError as any)?.message,
    txHash: borrowTxHash as `0x${string}` | undefined,
  };
} 