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

export function useGetUserDepositsUSD() {
  const { address } = useAccount();
  const { userPools } = useGetUserPools();
  const [totalDepositsUSD, setTotalDepositsUSD] = useState(0);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    async function fetchDeposits() {
      if (!address || !userPools.length) {
        setTotalDepositsUSD(0);
        return;
      }
      setIsLoading(true);
      let total = 0;
      await Promise.all(userPools.map(async (pool) => {
        try {
          const cToken = await client.readContract({
            address: pool as `0x${string}`,
            abi: LendingPoolAbi.abi,
            functionName: 'cToken',
          });
          const collateral = await client.readContract({
            address: pool as `0x${string}`,
            abi: LendingPoolAbi.abi,
            functionName: 'collateralSupplied',
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
            args: [cToken as `0x${string}`, collateral as bigint],
          });
          total += Number(usdValue || 0);
        } catch (e) {
          // ignore error for this pool
        }
      }));
      setTotalDepositsUSD(total);
      setIsLoading(false);
    }
    fetchDeposits();
  }, [address, userPools]);

  return { totalDepositsUSD, isLoading };
} 