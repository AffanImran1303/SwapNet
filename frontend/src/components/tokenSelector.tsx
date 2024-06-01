import React, { useState } from 'react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Image from "next/image";

const TokenSelector = () => {
    const [selectedToken, setSelectedToken] = useState("");

    const tokens = [
        { name: "Bitcoin", symbol: "BTC", icon: "/tokenIcon/btc.png" },
        { name: "Ethereum", symbol: "ETH", icon: "/tokenIcon/eth.png" },
        { name: "Polygon", symbol: "MATIC", icon: "/tokenIcon/matic.png" },
        { name: "USD Coin", symbol: "USDC", icon: "/tokenIcon/usdc.png" },
        { name: "Tether", symbol: "USDT", icon: "/tokenIcon/usdt.png" }
    ];

    const handleSelectToken = (value) => {
        setSelectedToken(value);
    };

    return (
        <Select onValueChange={handleSelectToken}>
            <SelectTrigger className="text-[#F0D6FF] w-[133px] bg-bgSecondary h-full border-0">
                <SelectValue placeholder="TKN" />
            </SelectTrigger>
            <SelectContent className="bg-bgSecondary text-[#F0D6FF] border-0">
                {tokens.map((token) => (
                    <SelectItem key={token.symbol} value={token.symbol} className="flex justify-between items-center hover:bg-[#342D4B] rounded-md p-2">
                        <div className="flex items-center gap-2">
                            <Image src={token.icon} alt={`${token.name} logo`} width={24} height={24} />
                            {token.symbol}
                        </div>
                        {selectedToken === token.symbol && (
                            <Image src="/public/checkMark.png" alt="Selected" width={20} height={20} />
                        )}
                    </SelectItem>
                ))}
            </SelectContent>
        </Select>
    );
};

export default TokenSelector;
