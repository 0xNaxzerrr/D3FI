import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { Abi, parseEther } from 'viem';
import LendingPoolAbi from '../../abis/LendingPool.json';
import ERC20Abi from '../../abis/ERC20.json';
import { useState } from 'react';

/**
 * Hook pour déposer sur une LendingPool
 * @param poolAddress Adresse du contrat LendingPool
 * @param asset Adresse de l'asset (address(0) ou 0x... pour ETH)
 * @param amount Montant à déposer (string, en ETH ou token)
 * @returns { deposit, isApproving, isDepositPending, approveError, depositError }
 */
export function useDeposit({ poolAddress, asset, amount }: {
  poolAddress: `0x${string}`,
  asset: `0x${string}`,
  amount: string
}) {
  const [isApproving, setIsApproving] = useState(false);
  const [approveError, setApproveError] = useState<string | null>(null);
  const [depositError, setDepositError] = useState<string | null>(null);

  const { writeContract, isPending: isDepositPending, error: depositWriteError, data: depositTxHash } = useWriteContract();
  const { writeContract: writeApprove, isPending: isApprovePending, error: approveWriteError } = useWriteContract();

  // Helper to check if asset is ETH
  const isETH = asset === '0x0000000000000000000000000000000000000000' || asset === '0x2A9920d9c32A46e52e3B18802c60CAeF0ee45C31';

  // Approve and deposit logic
  const deposit = async () => {
    setApproveError(null);
    setDepositError(null);
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
      // Deposit
      writeContract({
        abi: LendingPoolAbi.abi as Abi,
        address: poolAddress,
        functionName: 'deposit',
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
    hash: depositTxHash as `0x${string}` | undefined,
  });

  return {
    deposit,
    isApproving: isApproving || isApprovePending,
    isDepositPending,
    isConfirming,
    isConfirmed,
    approveError,
    depositError: depositError || (depositWriteError as any)?.message,
    txHash: depositTxHash as `0x${string}` | undefined,
  };
} 