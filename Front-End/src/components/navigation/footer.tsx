export default function Footer() {
  return (
    <footer className="border-t border-[#FF8A65]/10 backdrop-blur-sm">
      <div className="container mx-auto px-6 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12">
          {/* Logo et Description */}
          <div className="col-span-1 md:col-span-2">
            <div className="text-2xl font-bold text-[#FF8A65] mb-4">D3FI</div>
            <p className="text-gray-400 mb-6 max-w-md">
              Un protocole DeFi innovant pour maximiser vos rendements et accéder à la liquidité instantanée
            </p>
          </div>
        </div>

        {/* Copyright */}
        <div className="border-t border-[#FF8A65]/10 mt-12 pt-8 text-center text-gray-400">
          <p>© 2025 D3FI.</p>
        </div>
      </div>
    </footer>
  );
}
