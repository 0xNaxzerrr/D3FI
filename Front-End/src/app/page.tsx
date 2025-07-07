import Image from "next/image";
import Background from "@/components/background";
import Header from "@/components/navigation/header";
import Footer from "@/components/navigation/footer";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#0A0A0A] text-white relative overflow-hidden">
        <Background />

      {/* Content */}
      <div className="relative">
        {/* Navigation */}
        <Header />

        {/* Hero Section */}
        <div className="container mx-auto px-6 py-20">
          <div className="max-w-3xl">
            <h1 className="text-6xl font-bold mb-6 leading-tight">
              Prêtez et empruntez des actifs numériques en toute sécurité
            </h1>
            <p className="text-xl text-gray-400 mb-12">
              Un protocole DeFi innovant pour maximiser vos rendements et accéder à la liquidité instantanée
            </p>
            <div className="flex gap-4">
              <button className="bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] px-8 py-4 rounded-full font-medium transition-colors border border-[#FF8A65]/20 backdrop-blur-sm cursor-pointer">
                Commencer
              </button>
              <button className="border border-[#FF8A65]/20 text-[#FF8A65] px-8 py-4 rounded-full font-medium hover:bg-[#FF8A65]/10 transition-colors backdrop-blur-sm cursor-pointer">
                En savoir plus
              </button>
            </div>
          </div>
        </div>

        {/* Stats Section */}
        <div className="container mx-auto px-6 py-20">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="bg-black/40 p-8 rounded-2xl border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 transition-colors backdrop-blur-sm">
              <p className="text-gray-400 mb-2">TVL Total</p>
              <p className="text-3xl font-bold text-[#FF8A65]">$0.00</p>
              <p className="text-green-500 text-sm mt-2">+0.00%</p>
            </div>
            <div className="bg-black/40 p-8 rounded-2xl border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 transition-colors backdrop-blur-sm">
              <p className="text-gray-400 mb-2">Taux Moyen</p>
              <p className="text-3xl font-bold text-[#FF8A65]">0%</p>
              <p className="text-green-500 text-sm mt-2">APY</p>
            </div>
            <div className="bg-black/40 p-8 rounded-2xl border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 transition-colors backdrop-blur-sm">
              <p className="text-gray-400 mb-2">Prêts Actifs</p>
              <p className="text-3xl font-bold text-[#FF8A65]">0</p>
              <p className="text-gray-400 text-sm mt-2">en cours</p>
            </div>
            <div className="bg-black/40 p-8 rounded-2xl border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 transition-colors backdrop-blur-sm">
              <p className="text-gray-400 mb-2">Utilisateurs</p>
              <p className="text-3xl font-bold text-[#FF8A65]">0</p>
              <p className="text-gray-400 text-sm mt-2">actifs</p>
            </div>
          </div>
        </div>

        {/* Features Section */}
        <div className="container mx-auto px-6 py-20">
          <h2 className="text-4xl font-bold mb-16 text-center">Comment ça marche</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            <div className="text-center">
              <div className="bg-black/40 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-6 border border-[#FF8A65]/10 backdrop-blur-sm">
                <Image
                  src="/wallet.svg"
                  alt="Wallet"
                  width={32}
                  height={32}
                  className="dark:invert"
                />
              </div>
              <h3 className="text-xl font-semibold mb-4 text-[#FF8A65]">Connectez votre wallet</h3>
              <p className="text-gray-400">Connectez-vous avec votre wallet préféré pour commencer</p>
            </div>
            <div className="text-center">
              <div className="bg-black/40 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-6 border border-[#FF8A65]/10 backdrop-blur-sm">
                <Image
                  src="/deposit.svg"
                  alt="Deposit"
                  width={32}
                  height={32}
                  className="dark:invert"
                />
              </div>
              <h3 className="text-xl font-semibold mb-4 text-[#FF8A65]">Déposez vos actifs</h3>
              <p className="text-gray-400">Déposez vos actifs pour commencer à gagner des intérêts</p>
            </div>
            <div className="text-center">
              <div className="bg-black/40 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-6 border border-[#FF8A65]/10 backdrop-blur-sm">
                <Image
                  src="/earn.svg"
                  alt="Earn"
                  width={32}
                  height={32}
                  className="dark:invert"
                />
              </div>
              <h3 className="text-xl font-semibold mb-4 text-[#FF8A65]">Gagnez des rendements</h3>
              <p className="text-gray-400">Gagnez des rendements compétitifs sur vos dépôts</p>
            </div>
          </div>
        </div>

        {/* CTA Section */}
        <div className="container mx-auto px-6 py-20">
          <div className="bg-black/40 rounded-2xl p-12 text-center border border-[#FF8A65]/10 backdrop-blur-sm">
            <h2 className="text-4xl font-bold mb-6">Prêt à commencer ?</h2>
            <p className="text-gray-400 mb-8 max-w-2xl mx-auto">
              Rejoignez notre communauté et commencez à gagner des rendements sur vos actifs numériques dès aujourd'hui
            </p>
            <button className="bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] px-8 py-4 rounded-full font-medium transition-colors border border-[#FF8A65]/20 backdrop-blur-sm cursor-pointer">
              Commencer maintenant
            </button>
          </div>
        </div>

        {/* Footer */}
        <Footer />
      </div>
    </div>
  );
}
