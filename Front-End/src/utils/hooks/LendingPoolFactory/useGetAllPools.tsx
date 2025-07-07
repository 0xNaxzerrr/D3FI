"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import LendingPoolFactoryAbi from "../../abis/LendingPoolFactory.json";
import { Abi } from 'viem';

type AllPoolsContextType = {
    allPools: string[];
    isLoading: boolean;
    isSuccess: boolean;
    error: string;
};

const AllPoolsContext = createContext<AllPoolsContextType>({ allPools: [], isLoading: false, isSuccess: false, error: '' });

export const AllPoolsProvider = ({ children }: { children: React.ReactNode }) => {
    const [allPools, setAllPools] = useState<string[]>([]);
    const [error, setError] = useState('');

    const { address } = useAccount();

    const { data, isError, isLoading, error: readError, isSuccess } = useReadContract({
        address: process.env.NEXT_PUBLIC_LENDING_POOL_FACTORY_ADDRESS! as `0x${string}`,
        abi: LendingPoolFactoryAbi.abi as Abi,
        functionName: 'getAllPools',
        args: [],
    });

    useEffect(() => {
        console.log(isError);
        console.log(readError);
        console.log(isSuccess);
        console.log(data);
        console.log(address);
        
        if (isError && readError) {
            setError(readError.message);
        } else if (data) {
            console.log(data);
            setAllPools(data as string[]);
        }
    }, [data, isError, readError, address]);

    return (
        <AllPoolsContext.Provider value={{ allPools, isLoading, isSuccess, error }}>
            {children}
        </AllPoolsContext.Provider>
    );
};

export const useGetAllPools = () => useContext(AllPoolsContext);