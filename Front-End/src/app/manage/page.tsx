'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Background from '@/components/background';
import Header from '@/components/navigation/header';
import Footer from '@/components/navigation/footer';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useGetUserBorrows } from '@/utils/hooks/LendingPool/useGetUserBorrows';

interface Position {
  id: string;
  type: 'deposit' | 'borrow';
  token: {
    name: string;
    symbol: string;
    icon: string;
  };
  amount: number;
  value: number;
  apy: number;
  timestamp: string;
}

const positions: Position[] = [
  {
    id: '1',
    type: 'deposit',
    token: {
      name: 'Ethereum',
      symbol: 'ETH',
      icon: '/eth.svg'
    },
    amount: 0.5,
    value: 1750,
    apy: 3.2,
    timestamp: '2024-03-15'
  },
  {
    id: '2',
    type: 'borrow',
    token: {
      name: 'USD Coin',
      symbol: 'USDC',
      icon: '/usdc.svg'
    },
    amount: 1000,
    value: 1000,
    apy: 4.1,
    timestamp: '2024-03-14'
  }
];

export default function ManagePage() {
  const searchParams = useSearchParams();
  const pool = searchParams.get('pool');
  const { userBorrows, isLoading, isSuccess, error } = useGetUserBorrows(pool as `0x${string}`);
  const [selectedPosition, setSelectedPosition] = useState<Position>(positions[0]);
  const [amount, setAmount] = useState('');

  const handleAction = () => {
    // TODO: Implement withdraw/repay logic
    console.log(selectedPosition.type === 'deposit' ? 'Withdrawing' : 'Repaying', amount, selectedPosition.token.symbol);
  };

  return (
    <div className="min-h-screen bg-background text-white relative overflow-hidden">
      <Background />
      
      {/* Content */}
      <div className="relative">
        <Header />

        {/* Manage Content */}
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
            <h1 className="text-4xl font-bold mb-2">Gérer vos positions</h1>
            <p className="text-gray-400">Retirez vos dépôts ou remboursez vos prêts</p>
          </div>

          <div className="max-w-2xl mx-auto">
            {/* Positions List */}
            <div className="mb-8">
              <h2 className="text-xl font-semibold mb-4">Vos positions</h2>
              <div className="space-y-4">
                {positions.map((position) => (
                  <button
                    key={position.id}
                    onClick={() => setSelectedPosition(position)}
                    className={`w-full p-4 rounded-2xl border transition-colors backdrop-blur-sm cursor-pointer text-left ${
                      selectedPosition.id === position.id
                        ? 'bg-[#FF8A65]/10 border-[#FF8A65]/20'
                        : 'bg-black/40 border-[#FF8A65]/10 hover:border-[#FF8A65]/20'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-[#FF8A65]/10 flex items-center justify-center">
                          <Image
                            src={position.token.icon}
                            alt={position.token.name}
                            width={24}
                            height={24}
                            className="dark:invert"
                          />
                        </div>
                        <div>
                          <p className="font-medium">{position.token.name}</p>
                          <p className="text-sm text-gray-400">
                            {position.type === 'deposit' ? 'Dépôt' : 'Prêt'} • {position.timestamp}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-medium">{position.amount} {position.token.symbol}</p>
                        <p className="text-sm text-gray-400">${position.value.toLocaleString()}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-medium text-[#FF8A65]">{position.apy}% APY</p>
                        <p className="text-sm text-gray-400">
                          {position.type === 'deposit' ? 'Rendement' : 'Intérêt'}
                        </p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Action Form */}
            <div className="bg-black/40 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm p-6">
              <div className="mb-6">
                <label className="block text-gray-400 mb-2">
                  {selectedPosition.type === 'deposit' ? 'Montant à retirer' : 'Montant à rembourser'}
                </label>
                <div className="relative">
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full px-4 py-3 rounded-xl bg-black/40 text-white border border-[#FF8A65]/10 focus:border-[#FF8A65]/20 focus:ring-1 focus:ring-[#FF8A65]/20 backdrop-blur-sm focus:outline-none"
                  />
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
                    <span className="text-gray-400">{selectedPosition.token.symbol}</span>
                    <button
                      onClick={() => setAmount(selectedPosition.amount.toString())}
                      className="text-[#FF8A65] text-sm hover:underline cursor-pointer"
                    >
                      MAX
                    </button>
                  </div>
                </div>
                <div className="flex justify-between text-sm mt-2">
                  <span className="text-gray-400">Solde disponible</span>
                  <span className="text-white">{selectedPosition.amount} {selectedPosition.token.symbol}</span>
                </div>
              </div>

              {/* Action Info */}
              <div className="space-y-3 mb-6">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">APY</span>
                  <span className="text-[#FF8A65]">{selectedPosition.apy}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Valeur estimée</span>
                  <span className="text-white">
                    {amount ? (parseFloat(amount) * (selectedPosition.value / selectedPosition.amount)).toFixed(2) : '0.00'} USD
                  </span>
                </div>
              </div>

              {/* Action Button */}
              <button
                onClick={handleAction}
                disabled={!amount || parseFloat(amount) <= 0}
                className={`w-full py-3 rounded-xl font-medium transition-colors cursor-pointer ${
                  amount && parseFloat(amount) > 0
                    ? 'bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] border border-[#FF8A65]/20'
                    : 'bg-black/40 text-gray-500 border border-gray-700 cursor-not-allowed'
                } backdrop-blur-sm`}
              >
                {selectedPosition.type === 'deposit' ? 'Retirer' : 'Rembourser'} {selectedPosition.token.symbol}
              </button>
            </div>
          </div>
        </div>

        <Footer />
      </div>
    </div>
  );
} 