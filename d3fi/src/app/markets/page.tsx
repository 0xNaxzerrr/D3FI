'use client';

import { useState } from 'react';
import Image from 'next/image';
import Background from '@/components/background';
import Header from '@/components/navigation/header';
import Footer from '@/components/navigation/footer';

interface Market {
  id: string;
  token: string;
  symbol: string;
  supplyAPY: number;
  borrowAPY: number;
  totalSupply: number;
  totalBorrow: number;
  utilization: number;
  icon: string;
}

const markets: Market[] = [
  {
    id: 'eth',
    token: 'Ethereum',
    symbol: 'ETH',
    supplyAPY: 3.2,
    borrowAPY: 4.5,
    totalSupply: 1250000,
    totalBorrow: 450000,
    utilization: 36,
    icon: '/eth.svg'
  },
  {
    id: 'usdc',
    token: 'USD Coin',
    symbol: 'USDC',
    supplyAPY: 2.8,
    borrowAPY: 4.1,
    totalSupply: 8500000,
    totalBorrow: 3200000,
    utilization: 37.6,
    icon: '/usdc.svg'
  },
  {
    id: 'dai',
    token: 'Dai',
    symbol: 'DAI',
    supplyAPY: 2.5,
    borrowAPY: 3.8,
    totalSupply: 6500000,
    totalBorrow: 2400000,
    utilization: 36.9,
    icon: '/dai.svg'
  }
];

export default function MarketsPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState<'supply' | 'borrow'>('supply');

  const filteredMarkets = markets.filter(market =>
    market.token.toLowerCase().includes(searchTerm.toLowerCase()) ||
    market.symbol.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const sortedMarkets = [...filteredMarkets].sort((a, b) => {
    if (sortBy === 'supply') {
      return b.supplyAPY - a.supplyAPY;
    }
    return a.borrowAPY - b.borrowAPY;
  });

  return (
    <div className="min-h-screen bg-background text-white relative overflow-hidden">
      <Background />
      
      {/* Content */}
      <div className="relative">
        <Header />

        {/* Markets Content */}
        <div className="container mx-auto px-6 py-12">
          {/* Header */}
          <div className="mb-12">
            <h1 className="text-4xl font-bold mb-2">Marchés</h1>
            <p className="text-gray-400">Fournissez et empruntez des actifs sur D3FI</p>
          </div>

          {/* Search and Filter */}
          <div className="flex flex-col sm:flex-row gap-4 mb-8">
            <div className="flex-1">
              <input
                type="text"
                placeholder="Rechercher par nom ou symbole"
                className="w-full px-4 py-3 rounded-full bg-black/40 text-white border border-[#FF8A65]/10 focus:border-[#FF8A65]/20 focus:ring-1 focus:ring-[#FF8A65]/20 backdrop-blur-sm"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <div className="flex gap-4">
              <button
                className={`px-6 py-3 rounded-full transition-colors cursor-pointer ${
                  sortBy === 'supply'
                    ? 'bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] border border-[#FF8A65]/20'
                    : 'bg-black/40 text-gray-400 hover:text-white border border-[#FF8A65]/10 hover:border-[#FF8A65]/20'
                } backdrop-blur-sm`}
                onClick={() => setSortBy('supply')}
              >
                Trier par APY Supply
              </button>
              <button
                className={`px-6 py-3 rounded-full transition-colors cursor-pointer ${
                  sortBy === 'borrow'
                    ? 'bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] border border-[#FF8A65]/20'
                    : 'bg-black/40 text-gray-400 hover:text-white border border-[#FF8A65]/10 hover:border-[#FF8A65]/20'
                } backdrop-blur-sm`}
                onClick={() => setSortBy('borrow')}
              >
                Trier par APY Borrow
              </button>
            </div>
          </div>

          {/* Markets Table */}
          <div className="bg-black/40 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm overflow-hidden mb-12">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[#FF8A65]/10">
                    <th className="px-6 py-4 text-left text-gray-400 font-medium">Actif</th>
                    <th className="px-6 py-4 text-right text-gray-400 font-medium">APY Supply</th>
                    <th className="px-6 py-4 text-right text-gray-400 font-medium">APY Borrow</th>
                    <th className="px-6 py-4 text-right text-gray-400 font-medium">Total Supply</th>
                    <th className="px-6 py-4 text-right text-gray-400 font-medium">Total Borrow</th>
                    <th className="px-6 py-4 text-right text-gray-400 font-medium">Utilisation</th>
                    <th className="px-6 py-4 text-right text-gray-400 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {sortedMarkets.map((market) => (
                    <tr key={market.id} className="border-b border-[#FF8A65]/10 hover:bg-[#FF8A65]/5 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-[#FF8A65]/10 flex items-center justify-center">
                            <Image
                              src={market.icon}
                              alt={market.token}
                              width={24}
                              height={24}
                              className="dark:invert"
                            />
                          </div>
                          <div>
                            <div className="text-white font-medium">{market.token}</div>
                            <div className="text-gray-400 text-sm">{market.symbol}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <span className="text-[#FF8A65] font-medium">{market.supplyAPY}%</span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <span className="text-[#FF8A65] font-medium">{market.borrowAPY}%</span>
                      </td>
                      <td className="px-6 py-4 text-right text-white">
                        ${market.totalSupply.toLocaleString()}
                      </td>
                      <td className="px-6 py-4 text-right text-white">
                        ${market.totalBorrow.toLocaleString()}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <div className="w-16 h-2 bg-black/40 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-[#FF8A65]"
                              style={{ width: `${market.utilization}%` }}
                            />
                          </div>
                          <span className="text-gray-400">{market.utilization}%</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex justify-end gap-2">
                          <button className="bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] px-4 py-2 rounded-full text-sm font-medium transition-colors border border-[#FF8A65]/20 backdrop-blur-sm cursor-pointer">
                            Supply
                          </button>
                          <button className="bg-black/40 text-white px-4 py-2 rounded-full text-sm font-medium transition-colors border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 backdrop-blur-sm cursor-pointer">
                            Borrow
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Market Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
              <h3 className="text-gray-400 mb-2">Total Value Locked</h3>
              <p className="text-3xl font-bold text-[#FF8A65]">$17.4M</p>
              <p className="text-green-500 text-sm mt-2">+0.00%</p>
            </div>
            <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
              <h3 className="text-gray-400 mb-2">Total Borrowed</h3>
              <p className="text-3xl font-bold text-[#FF8A65]">$6.05M</p>
              <p className="text-gray-400 text-sm mt-2">en cours</p>
            </div>
            <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
              <h3 className="text-gray-400 mb-2">Available to Borrow</h3>
              <p className="text-3xl font-bold text-[#FF8A65]">$11.35M</p>
              <p className="text-gray-400 text-sm mt-2">disponible</p>
            </div>
          </div>
        </div>

        <Footer />
      </div>
    </div>
  );
} 