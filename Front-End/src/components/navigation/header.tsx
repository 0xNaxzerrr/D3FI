"use client";

import { ConnectKitButton } from "connectkit";
import Link from "next/link";

export default function Header() {
  return (
    <nav className="container mx-auto px-6 py-6 flex justify-between items-center backdrop-blur-sm">
      <Link href="/" className="text-3xl font-bold text-[#FF8A65]">D3FI</Link>
      <div className="flex gap-6 items-center">
        <Link href="/dashboard" className="text-gray-400 hover:text-[#FF8A65] transition-colors">Dashboard</Link>
        <Link href="/markets" className="text-gray-400 hover:text-[#FF8A65] transition-colors">Markets</Link>
        <ConnectKitButton />
      </div>
    </nav>
  );
}
