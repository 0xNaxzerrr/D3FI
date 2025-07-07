import { useEffect, useState } from 'react';
import { useReadContract } from 'wagmi';
import LendingPoolAbi from "../../abis/LendingPool.json";
import { Abi } from 'viem';

export function useGetCurrentInterestRate(contractAddress: `0x${string}`) {
    const [currentInterestRate, setCurrentInterestRate] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    const { data, isError, isLoading, error: readError, isSuccess } = useReadContract({
        address: contractAddress,
        abi: LendingPoolAbi.abi as Abi,
        functionName: 'currentInterestRate',
        args: [],
    });

    useEffect(() => {
        console.log(data);
        
        if (isError && readError) {
            setError(readError.message);
        } else if (data) {
            setCurrentInterestRate(data as string);
        }
    }, [data, isError, readError]);

    return { currentInterestRate, isLoading, isSuccess, error };
}