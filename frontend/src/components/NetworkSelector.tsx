import React, { useState } from 'react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import Image from "next/image";

const NetworkSelector = () => {
    const [selectedNetwork, setSelectedNetwork] = useState("");

    const networks = [
        { name: "Arbitrum", icon: "/networkIcon/arbitrum.png" },
        { name: "Avalanche", icon: "/networkIcon/avalanche.png" },
        { name: "Base", icon: "/networkIcon/base.png" },
        { name: "Binance", icon: "/networkIcon/binance.png" },
        { name: "Ethereum", icon: "/networkIcon/ethereum.png" },
        { name: "Kroma", icon: "/networkIcon/kroma.png" },
        { name: "Optimism", icon: "/networkIcon/optimism.png" },
        { name: "Polygon", icon: "/networkIcon/polygon.png" },
        { name: "WEMIX", icon: "/networkIcon/wemix.png" }
    ];


    return (
        <Select>
            <SelectTrigger className="text-[#F0D6FF] bg-bgSecondary w-[150px] h-[35px] rounded-2xl border-0">
                <SelectValue placeholder="Network" />
            </SelectTrigger>
            <SelectContent className="flex bg-panelPrimary text-[#F0D6FF] border-sm border-sliderPrimary pr-6">
                {networks.map((network) => (
                    <SelectItem key={network.name} value={network.name} className="flex justify-between items-between hover:bg-[#342D4B] rounded-2xl">
                        <div className="flex items-center gap-2">
                            <Image src={network.icon} alt={`${network.name} logo`} width={24} height={24} />
                            {network.name}
                        </div>
                        {selectedNetwork === network.name && (
                            <Image src="/public/checkMark.png" alt="Selected" width={20} height={20} />
                        )}
                    </SelectItem>
                ))}
            </SelectContent>
        </Select>
    );
};

export default NetworkSelector;