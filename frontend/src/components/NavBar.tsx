import { Button } from "@/components/ui/button";
import Link from "next/link";
import Image from "next/image";
import swapnetLogo from "../../public/SWAPNET.svg";
// import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useEffect, useRef } from "react";
import {
    useConnectModal,
    useAccountModal,
    useChainModal,
} from "@rainbow-me/rainbowkit";
import { useAccount, useDisconnect } from "wagmi";
import "@rainbow-me/rainbowkit/styles.css";


export default function NavBar() {

    const { isConnecting, address, isConnected, chain } = useAccount();
    const { openConnectModal } = useConnectModal();
    const { openAccountModal } = useAccountModal();
    const { openChainModal } = useChainModal();
    const { disconnect } = useDisconnect();

    const isMounted = useRef(false);

    useEffect(() => {
        isMounted.current = true;
    }, []);

    if (!isConnected) {
        return (
            <header className="flex justify-between items-center w-full p-4 bg-transparent">
                <span>
                    <Image src={swapnetLogo} alt='swapnet logo' width={182} height={40} />
                </span>
                <Button
                    className={'w-[142px] h-[40px] bg-buttonPrimary rounded-[8px] text-white'}
                    onClick={async () => {
                        // Disconnecting wallet first because sometimes when is connected but the user is not connected
                        if (isConnected) {
                            disconnect();
                        }
                        openConnectModal?.();
                    }}
                    disabled={isConnecting}
                >
                    {isConnecting ? 'Connecting...' : 'Connect wallet'}
                </Button>
                {/* <ConnectButton /> */}
            </header>
        );
    }

    if (isConnected && !chain) {
        return (
            <header className="flex justify-between items-center w-full p-4 bg-transparent">
                <span>
                    <Image src={swapnetLogo} alt='swapnet logo' width={182} height={40} />
                </span>
                <Button
                    className={'w-[142px] h-[40px] bg-buttonPrimary rounded-[8px] text-white'}
                    onClick={openChainModal}
                >
                    Wrong network
                </Button>
            </header>
        );
    }


    return (
        <header className="flex justify-between items-center w-full p-4 bg-transparent">
            <span>
                <Image src={swapnetLogo} alt='swapnet logo' width={182} height={40} />
            </span>
            {isConnected ? (<Button className={'w-[142px] h-[40px] bg-buttonPrimary rounded-[8px] text-white'} onClick={async () => openAccountModal?.()}>
                Switch Network
            </Button>) : ''}
        </header>
    )
}