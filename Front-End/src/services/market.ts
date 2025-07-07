import { MARKETS } from "@/utils/constants/MARKETS";

export function getPoolDatasByAddress(address: string){
    const market = MARKETS.find(market => market.address === address);
    if(!market){
        return null;
    }
    return market;
}