import { useAccount } from 'wagmi';
import { useGetUserPools } from './LendingPoolFactory/useGetUserPools';
import { useEffect, useState } from 'react';
import LendingPoolAbi from '../abis/LendingPool.json';
import PriceOracleAbi from '../abis/PriceOracle.json';
import { createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';

const client = createPublicClient({
  chain: sepolia, // adapte à ta chaîne
  transport: http(),
});

export function useGetUserBorrowsUSD() {
  const { address } = useAccount();
  const { userPools } = useGetUserPools();
  const [totalBorrowsUSD, setTotalBorrowsUSD] = useState(0);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    async function fetchBorrows() {
      if (!address || !userPools.length) {
        setTotalBorrowsUSD(0);
        return;
      }
      setIsLoading(true);
      let total = 0;
      await Promise.all(userPools.map(async (pool) => {
        try {
          const asset = await client.readContract({
            address: pool as `0x${string}`,
            abi: LendingPoolAbi.abi,
            functionName: 'asset',
          });
          const borrows = await client.readContract({
            address: pool as `0x${string}`,
            abi: LendingPoolAbi.abi,
            functionName: 'userBorrows',
            args: [address],
          });
          const priceOracle = await client.readContract({
            address: pool as `0x${string}`,
            abi: LendingPoolAbi.abi,
            functionName: 'priceOracle',
          });
          const usdValue = await client.readContract({
            address: priceOracle as `0x${string}`,
            abi: PriceOracleAbi,
            functionName: 'assetToUsd',
            args: [asset as `0x${string}`, borrows as bigint],
          });
          total += Number(usdValue || 0);
        } catch (e) {
          // ignore error for this pool
        }
      }));
      setTotalBorrowsUSD(total);
      setIsLoading(false);
    }
    fetchBorrows();
  }, [address, userPools]);

  return { totalBorrowsUSD, isLoading };
} 