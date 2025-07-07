import { useEffect, useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import LendingPoolAbi from "../../abis/LendingPool.json";
import { Abi } from 'viem';

export function useGetUserBorrows(contractAddress: `0x${string}`) {
    const [userBorrows, setUserBorrows] = useState<number | null>(null);
    const [error, setError] = useState<string | null>(null);

    const { address } = useAccount();

    const { data, isError, isLoading, error: readError, isSuccess } = useReadContract({
        address: contractAddress,
        abi: LendingPoolAbi.abi as Abi,
        functionName: 'userBorrows',
        args: [address as `0x${string}`],
    });

    useEffect(() => {
        console.log(data);
        
        if (isError && readError) {
            setError(readError.message);
        } else if (data) {
            setUserBorrows(Number(data));
        }
    }, [data, isError, readError]);

    return { userBorrows, isLoading, isSuccess, error };
}