'use client';

import { useState } from 'react';
import Image from 'next/image';
import Background from '@/components/background';
import Header from '@/components/navigation/header';
import Footer from '@/components/navigation/footer';
import Link from 'next/link';

interface Token {
  id: string;
  name: string;
  symbol: string;
  icon: string;
  availableToBorrow: number;
  borrowAPY: number;
  collateralFactor: number;
}

const tokens: Token[] = [
  {
    id: 'eth',
    name: 'Ethereum',
    symbol: 'ETH',
    icon: '/eth.svg',
    availableToBorrow: 250000,
    borrowAPY: 4.5,
    collateralFactor: 0.8
  },
  {
    id: 'usdc',
    name: 'USD Coin',
    symbol: 'USDC',
    icon: '/usdc.svg',
    availableToBorrow: 5000000,
    borrowAPY: 4.1,
    collateralFactor: 0.85
  },
  {
    id: 'dai',
    name: 'Dai',
    symbol: 'DAI',
    icon: '/dai.svg',
    availableToBorrow: 3000000,
    borrowAPY: 3.8,
    collateralFactor: 0.85
  }
];

export default function BorrowPage() {
  const [selectedToken, setSelectedToken] = useState<Token>(tokens[0]);
  const [amount, setAmount] = useState('');
  const [collateralToken, setCollateralToken] = useState('ETH');

  const handleBorrow = () => {
    // TODO: Implement borrow logic
    console.log('Borrowing', amount, selectedToken.symbol, 'with', collateralToken, 'as collateral');
  };

  return (
    <div className="min-h-screen bg-background text-white relative overflow-hidden">
      <Background />
      
      {/* Content */}
      <div className="relative">
        <Header />

        {/* Borrow Content */}
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
            <h1 className="text-4xl font-bold mb-2">Emprunter des actifs</h1>
            <p className="text-gray-400">Empruntez des actifs en utilisant vos dépôts comme garantie</p>
          </div>

          <div className="max-w-2xl mx-auto">
            {/* Token Selection */}
            <div className="mb-8">
              <h2 className="text-xl font-semibold mb-4">Sélectionner un actif à emprunter</h2>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {tokens.map((token) => (
                  <button
                    key={token.id}
                    onClick={() => setSelectedToken(token)}
                    className={`p-4 rounded-2xl border transition-colors backdrop-blur-sm cursor-pointer text-left ${
                      selectedToken.id === token.id
                        ? 'bg-[#FF8A65]/10 border-[#FF8A65]/20'
                        : 'bg-black/40 border-[#FF8A65]/10 hover:border-[#FF8A65]/20'
                    }`}
                  >
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 rounded-full bg-[#FF8A65]/10 flex items-center justify-center">
                        <Image
                          src={token.icon}
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
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-400">Disponible</span>
                      <span className="text-white">${token.availableToBorrow.toLocaleString()}</span>
                    </div>
                    <div className="flex justify-between text-sm mt-1">
                      <span className="text-gray-400">APY</span>
                      <span className="text-[#FF8A65]">{token.borrowAPY}%</span>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Borrow Form */}
            <div className="bg-black/40 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm p-6 mb-8">
              <div className="mb-6">
                <label className="block text-gray-400 mb-2">Montant à emprunter</label>
                <div className="relative">
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full px-4 py-3 rounded-xl bg-black/40 text-white border border-[#FF8A65]/10 focus:border-[#FF8A65]/20 focus:ring-1 focus:ring-[#FF8A65]/20 backdrop-blur-sm focus:outline-none"
                  />
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
                    <span className="text-gray-400">{selectedToken.symbol}</span>
                    <button
                      onClick={() => setAmount(selectedToken.availableToBorrow.toString())}
                      className="text-[#FF8A65] text-sm hover:underline cursor-pointer"
                    >
                      MAX
                    </button>
                  </div>
                </div>
              </div>

              {/* Collateral Selection */}
              <div className="mb-6">
                <label className="block text-gray-400 mb-2">Actif de garantie</label>
                <select
                  value={collateralToken}
                  onChange={(e) => setCollateralToken(e.target.value)}
                  className="w-full px-4 py-3 rounded-xl bg-black/40 text-white border border-[#FF8A65]/10 focus:border-[#FF8A65]/20 focus:ring-1 focus:ring-[#FF8A65]/20 backdrop-blur-sm focus:outline-none cursor-pointer"
                >
                  <option value="ETH">ETH - Ethereum</option>
                  <option value="USDC">USDC - USD Coin</option>
                  <option value="DAI">DAI - Dai</option>
                </select>
              </div>

              {/* Borrow Info */}
              <div className="space-y-3 mb-6">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">APY d'emprunt</span>
                  <span className="text-[#FF8A65]">{selectedToken.borrowAPY}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Facteur de garantie</span>
                  <span className="text-white">{selectedToken.collateralFactor * 100}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Intérêts annuels estimés</span>
                  <span className="text-white">
                    {amount ? ((parseFloat(amount) * selectedToken.borrowAPY) / 100).toFixed(2) : '0.00'} {selectedToken.symbol}
                  </span>
                </div>
              </div>

              {/* Borrow Button */}
              <button
                onClick={handleBorrow}
                disabled={!amount || parseFloat(amount) <= 0}
                className={`w-full py-3 rounded-xl font-medium transition-colors cursor-pointer ${
                  amount && parseFloat(amount) > 0
                    ? 'bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] border border-[#FF8A65]/20'
                    : 'bg-black/40 text-gray-500 border border-gray-700 cursor-not-allowed'
                } backdrop-blur-sm`}
              >
                Emprunter {selectedToken.symbol}
              </button>
            </div>
          </div>
        </div>

        <Footer />
      </div>
    </div>
  );
} 