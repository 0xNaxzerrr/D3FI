'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Background from '@/components/background';
import Header from '@/components/navigation/header';
import Footer from '@/components/navigation/footer';
import Link from 'next/link';
import { useGetAllPools } from '@/utils/hooks/LendingPoolFactory/useGetAllPools';
import { Market } from '@/utils/types/marketType';
import { getPoolDatasByAddress } from '@/services/market';
import { useDeposit } from '@/utils/hooks/LendingPool/useDeposit';
import { MARKETS } from '@/utils/constants/MARKETS';
import { useAccount } from 'wagmi';

export default function DepositPage() {
  const { allPools, isLoading, isSuccess, error } = useGetAllPools();
  const { address } = useAccount();
  const [tokens, setTokens] = useState<Market[]>([]);
  const [selectedToken, setSelectedToken] = useState<Market | null>(null);
  const [amount, setAmount] = useState('');
  const [userError, setUserError] = useState<string | null>(null);

  useEffect(() => {
    setTokens(MARKETS);
    setSelectedToken(MARKETS[0]);
  }, [allPools]);

  const poolAddress = allPools[tokens.findIndex(t => t.address === selectedToken?.address)] as `0x${string}` | undefined;
  const depositHook = useDeposit({
    poolAddress: poolAddress || ('' as `0x${string}`),
    asset: selectedToken?.address || ('' as `0x${string}`),
    amount
  });

  const handleDeposit = () => {
    setUserError(null);
    if (!address) {
      setUserError('Veuillez connecter votre wallet pour déposer.');
      return;
    }
    if (!depositHook.isApproving && !depositHook.isDepositPending) {
      depositHook.deposit();
    }
  };

  return (
    <div className="min-h-screen bg-background text-white relative overflow-hidden">
      <Background />
      
      {/* Content */}
      <div className="relative">
        <Header />

        {/* Deposit Content */}
        <div className="container mx-auto px-6 pb-12">
          {/* Return button */}
          <Link 
            href="/dashboard" 
            className="inline-flex items-center text-gray-400 hover:text-white mb-8 mt-4 transition-colors"
          >
            <svg 
              width="20" 
              height="20" 
              viewBox="0 0 20 20" 
              fill="none" 
              xmlns="http://www.w3.org/2000/svg"
            >
              <path 
                d="M12.5 15L7.5 10L12.5 5" 
                stroke="currentColor" 
                strokeWidth="2" 
                strokeLinecap="round" 
                strokeLinejoin="round"
              />
            </svg>
            Retour au Dashboard
          </Link>

          {/* Header */}
          <div className="mb-12">
            <h1 className="text-4xl font-bold mb-2">Déposer des actifs</h1>
            <p className="text-gray-400">Déposez vos actifs pour commencer à gagner des rendements</p>
          </div>

          <div className="max-w-2xl mx-auto">
            {/* Token Selection */}
            <div className="mb-8">
              <h2 className="text-xl font-semibold mb-4">Sélectionner un actif</h2>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {tokens.map((token: Market) => (
                  <button
                    key={token.address}
                    onClick={() => setSelectedToken(token)}
                    className={`p-4 rounded-2xl border transition-colors backdrop-blur-sm cursor-pointer text-left ${
                      selectedToken?.address === token.address
                        ? 'bg-[#FF8A65]/10 border-[#FF8A65]/20'
                        : 'bg-black/40 border-[#FF8A65]/10 hover:border-[#FF8A65]/20'
                    }`}
                  >
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 rounded-full bg-[#FF8A65]/10 flex items-center justify-center">
                        <Image
                          src={token.logo}
                          alt={token.name}
                          width={24}
                          height={24}
                          className="dark:invert"
                        />
                      </div>
                      <div>
                        <p className="font-medium">{token.symbol}</p>
                        <p className="text-sm text-gray-400">{token.name}</p>
                      </div>
                    </div>
                    <div className="flex justify-between text-sm mt-1">
                      <span className="text-gray-400">APY</span>
                      <span className="text-[#FF8A65]">{token.apy/100}%</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Deposit Form */}
            <div className="bg-black/40 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm p-6 mb-8">
              <div className="mb-6">
                <label className="block text-gray-400 mb-2">Montant à déposer</label>
                <div className="relative">
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full px-4 py-3 rounded-xl bg-black/40 text-white border border-[#FF8A65]/10 focus:border-[#FF8A65]/20 focus:ring-1 focus:ring-[#FF8A65]/20 backdrop-blur-sm focus:outline-none"
                  />
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
                    <span className="text-gray-400">{selectedToken?.symbol}</span>
                  </div>
                </div>
              </div>

              {/* Deposit Info */}
              <div className="space-y-3 mb-6">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">APY estimé</span>
                  <span className="text-[#FF8A65]">{selectedToken?.apy ? (selectedToken.apy/100) : 0}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Rendement annuel estimé</span>
                  <span className="text-white">
                    {amount ? ((parseFloat(amount) * selectedToken?.apy!) / 100).toFixed(2) : '0.00'} {selectedToken?.symbol}
                  </span>
                </div>
              </div>

              {/* Deposit Button */}
              <button
                onClick={handleDeposit}
                disabled={!address || !amount || parseFloat(amount) <= 0 || depositHook.isApproving || depositHook.isDepositPending}
                className={`w-full py-3 rounded-xl font-medium transition-colors cursor-pointer ${
                  address && amount && parseFloat(amount) > 0 && !depositHook.isApproving && !depositHook.isDepositPending
                    ? 'bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] border border-[#FF8A65]/20'
                    : 'bg-black/40 text-gray-500 border border-gray-700 cursor-not-allowed'
                } backdrop-blur-sm`}
              >
                {depositHook.isApproving
                  ? 'Approval en cours...'
                  : depositHook.isDepositPending
                  ? 'Dépôt en cours...'
                  : `Déposer ${selectedToken?.symbol}`}
              </button>
              {userError && (
                <div className="text-red-400 text-sm mt-2">{userError}</div>
              )}
              {depositHook.approveError && (
                <div className="text-red-400 text-sm mt-2">{depositHook.approveError}</div>
              )}
              {depositHook.depositError && (
                <div className="text-red-400 text-sm mt-2">{depositHook.depositError}</div>
              )}
              {depositHook.isConfirmed && (
                <div className="text-green-400 text-sm mt-2">Dépôt confirmé !</div>
              )}
            </div>

          </div>
        </div>

        <Footer />
      </div>
    </div>
  );
}