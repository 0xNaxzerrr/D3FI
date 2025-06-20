import Image from "next/image";
import Background from "@/components/background";
import Header from "@/components/navigation/header";
import Footer from "@/components/navigation/footer";
import Link from "next/link";

export default function Dashboard() {
    return (
        <div className="min-h-screen bg-background text-white relative overflow-hidden">
            <Background />

            {/* Content */}
            <div className="relative">
                <Header />

                {/* Dashboard Content */}
                <div className="container mx-auto px-6 py-12">
                    {/* Welcome Section */}
                    <div className="mb-12">
                        <h1 className="text-4xl font-bold mb-2">Bienvenue sur votre Dashboard</h1>
                        <p className="text-gray-400">Gérez vos actifs et suivez vos rendements</p>
                    </div>

                    {/* Portfolio Overview */}
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-12">
                        <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
                            <p className="text-gray-400 mb-2">Valeur Totale</p>
                            <p className="text-3xl font-bold text-[#FF8A65]">$0.00</p>
                            <p className="text-green-500 text-sm mt-2">+0.00%</p>
                        </div>
                        <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
                            <p className="text-gray-400 mb-2">Dépôts</p>
                            <p className="text-3xl font-bold text-[#FF8A65]">$0.00</p>
                            <p className="text-gray-400 text-sm mt-2">en cours</p>
                        </div>
                        <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
                            <p className="text-gray-400 mb-2">Prêts</p>
                            <p className="text-3xl font-bold text-[#FF8A65]">$0.00</p>
                            <p className="text-gray-400 text-sm mt-2">en cours</p>
                        </div>
                        <div className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm">
                            <p className="text-gray-400 mb-2">Rendements</p>
                            <p className="text-3xl font-bold text-[#FF8A65]">$0.00</p>
                            <p className="text-green-500 text-sm mt-2">APY: 0%</p>
                        </div>
                    </div>

                    {/* Active Positions */}
                    <div className="mb-12">
                        <h2 className="text-2xl font-bold mb-6">Positions Actives</h2>
                        <div className="bg-black/40 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm overflow-hidden">
                            <div className="p-6">
                                <div className="flex items-center justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-full bg-[#FF8A65]/10 flex items-center justify-center">
                                            <Image
                                                src="/eth.svg"
                                                alt="ETH"
                                                width={24}
                                                height={24}
                                                className="dark:invert"
                                            />
                                        </div>
                                        <div>
                                            <p className="font-medium">ETH</p>
                                            <p className="text-sm text-gray-400">Ethereum</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-medium">0.00 ETH</p>
                                        <p className="text-sm text-gray-400">$0.00</p>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-medium">0% APY</p>
                                        <p className="text-sm text-gray-400">Rendement</p>
                                    </div>
                                    <Link href={"/manage"} className="bg-[#FF8A65]/10 hover:bg-[#FF8A65]/20 text-[#FF8A65] px-4 py-2 rounded-full text-sm font-medium transition-colors border border-[#FF8A65]/20 backdrop-blur-sm cursor-pointer">
                                        Gérer
                                    </Link>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Recent Transactions */}
                    <div className="mb-12">
                        <h2 className="text-2xl font-bold mb-6">Transactions Récentes</h2>
                        <div className="bg-black/40 rounded-2xl border border-[#FF8A65]/10 backdrop-blur-sm overflow-hidden">
                            <div className="p-6">
                                <div className="flex items-center justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-full bg-[#FF8A65]/10 flex items-center justify-center">
                                            <Image
                                                src="/deposit.svg"
                                                alt="Deposit"
                                                width={24}
                                                height={24}
                                                className="dark:invert"
                                            />
                                        </div>
                                        <div>
                                            <p className="font-medium">Dépôt</p>
                                            <p className="text-sm text-gray-400">Il y a 0 jours</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-medium">0.00 ETH</p>
                                        <p className="text-sm text-gray-400">$0.00</p>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-medium text-green-500">Complété</p>
                                        <p className="text-sm text-gray-400">Transaction</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Quick Actions */}
                    <div>
                        <h2 className="text-2xl font-bold mb-6">Actions Rapides</h2>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <Link href="/deposit" className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 transition-colors backdrop-blur-sm text-left">
                                <div className="w-12 h-12 rounded-full bg-[#FF8A65]/10 flex items-center justify-center mb-4">
                                    <Image
                                        src="/deposit.svg"
                                        alt="Deposit"
                                        width={24}
                                        height={24}
                                        className="dark:invert"
                                    />
                                </div>
                                <h3 className="text-xl font-semibold mb-2">Déposer</h3>
                                <p className="text-gray-400">Déposez vos actifs pour commencer à gagner des rendements</p>
                            </Link>
                            <Link href="/borrow" className="bg-black/40 p-6 rounded-2xl border border-[#FF8A65]/10 hover:border-[#FF8A65]/20 transition-colors backdrop-blur-sm text-left">
                                <div className="w-12 h-12 rounded-full bg-[#FF8A65]/10 flex items-center justify-center mb-4">
                                    <Image
                                        src="/borrow.svg"
                                        alt="Borrow"
                                        width={24}
                                        height={24}
                                        className="dark:invert"
                                    />
                                </div>
                                <h3 className="text-xl font-semibold mb-2">Emprunter</h3>
                                <p className="text-gray-400">Empruntez des actifs en utilisant vos dépôts comme garantie</p>
                            </Link>
                        </div>
                    </div>
                </div>

                <Footer />
            </div>
        </div>
    );
} 