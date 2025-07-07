"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import LendingPoolFactoryAbi from "../../abis/LendingPoolFactory.json";
import { Abi } from 'viem';

type UserPoolsContextType = {
    userPools: string[];
    isLoading: boolean;
    isSuccess: boolean;
    error: string;
};

const UserPoolsContext = createContext<UserPoolsContextType>({ userPools: [], isLoading: false, isSuccess: false, error: '' });

export const UserPoolsProvider = ({ children }: { children: React.ReactNode }) => {
    const [userPools, setUserPools] = useState<string[]>([]);
    const [error, setError] = useState('');

    const { address } = useAccount();

    const { data, isError, isLoading, error: readError, isSuccess } = useReadContract({
        address: process.env.NEXT_PUBLIC_LENDING_POOL_FACTORY_ADDRESS! as `0x${string}`,
        abi: LendingPoolFactoryAbi.abi as Abi,
        functionName: 'getUserPools',
        args: [address],
    });

    useEffect(() => {
        if (isError && readError) {
            setError(readError.message);
        } else if (data) {
            setUserPools(data as string[]);
        }
    }, [data, isError, readError, address]);

    return (
        <UserPoolsContext.Provider value={{ userPools, isLoading, isSuccess, error }}>
            {children}
        </UserPoolsContext.Provider>
    );
};

export const useGetUserPools = () => useContext(UserPoolsContext);