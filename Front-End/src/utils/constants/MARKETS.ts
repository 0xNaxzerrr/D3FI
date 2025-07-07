import { Market } from "../types/marketType";

export const MARKETS: Market[] = [
    {
        name: "Ethereum",
        symbol: "ETH",
        address: "0x2A9920d9c32A46e52e3B18802c60CAeF0ee45C31" as `0x${string}`,
        price: 1000,
        logo: "/eth.svg",
        apy: 550
    },
    {
        name: "Link",
        symbol: "LINK",
        address: "0x370dFD59fa6cdd873fFaccEBb04bB7E662A9d086" as `0x${string}`,
        price: 1,
        logo: "/link.svg",
        apy: 500
    },
    {
        name: "Bitcoin",
        symbol: "BTC",
        address: "0x0000000000000000000000000000000000000000" as `0x${string}`,
        price: 1000,
        logo: "/btc.svg",
        apy: 500
    }
]