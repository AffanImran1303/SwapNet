'use client'
import NavBar from "@/components/NavBar";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import swapToken from "../../public/arrow-up-arrow-down.png"
import Image from "next/image";
import {useState} from "react";
import WalletConnectModal from "@/components/WalletConnectModal";
import NetworkSelector from "@/components/NetworkSelector";
import TokenSelector from "@/components/tokenSelector";


export default function Home() {
    const [fromToken, setFromToken] = useState("");
    const [fromAmount, setFromAmount] = useState("");
    const [fromFee, setFromFee] = useState(0);

    const [toAmount, setToAmount] = useState("");
    const [toToken, setToToken] = useState("");
    const [toFee, setToFee] = useState(0);
    const [isModalOpen, setIsModalOpen] = useState(false);

    function handleFromAmount(e){
        e.preventDefault()
        setFromAmount(e.target.value)
        setFromFee(calculateFee(fromAmount));
    }

    function handleToAmount(e) {
        e.preventDefault()
        setToAmount(e.target.value)
        setToFee(calculateFee(toAmount));
    }


    function calculateFee(amount) {
        return parseFloat(amount) * 0.01; 
    }

    const totalFee = fromFee + toFee;

    function handleConnect(walletName) {
        console.log(`Wallet connected: ${walletName}`);
        setIsModalOpen(false); 
    }

  return (
    <main className="flex min-h-screen flex-col items-center justify-between px-10 py-1 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-bgSecondary from-10% to-bgPrimary to-80% ">
      <NavBar/>
        <div className="text-[#F0D6FF] p-8 space-y-6 w-full max-w-2xl mt-4">
            <div className="flex gap-8">
                <span>Send:</span>
                <div className="flex flex-col">
                <NetworkSelector />
                    <div className="w-[600px] h-[140px] rounded-2xl flex bg-[#3E2F4C] my-2 items-center">
                        <div className='w-4/4'>
                            <Input name='from' placeholder='00.00' className="bg-transparent border-0 h-full text-center text-3xl font-bold text-gray-100" onChange={handleFromAmount}
                                   value={fromAmount}/>
                            <div className='bg-transparent border-0 text-center text-sm text-gray-100 text-opacity-50'>$ {fromAmount ? fromAmount : '00.00'}</div>
                        </div>
                        <TokenSelector />
                    </div>
                </div>
            </div>
        </div>
        <div>
        <Image src={swapToken} alt={'exchange token'} width={50} height={50} className={'cursor-pointer object-center justify-center absolute'}/>
        </div>
        <div className="text-[#F0D6FF] p-12 space-y-6 w-full max-w-3xl mt-4">
            <div className="flex gap-11">
                <span>Receive:</span>
                <div className="flex flex-col">
                <NetworkSelector />
                    <div className="w-[600px] h-[140px] rounded-2xl flex bg-[#3E2F4C] my-2 items-center">
                        <div className='w-4/4'>
                            <Input name='from' placeholder='00.00' className="bg-transparent border-0 h-full text-center text-3xl font-bold text-gray-400" onChange={handleToAmount}
                                   value={toAmount}/>
                            <div className='bg-transparent border-0 text-center text-sm text-gray-100 text-opacity-50'>$ {toAmount ? toAmount : '00.00'}</div>
                        </div>
                        <TokenSelector />
                    </div>
                    <div>
                        <p className="flex items-center justify-center my-5">Fees: ${totalFee.toFixed(2)} </p>
                    </div>
                    <div className="flex items-center justify-center">
                        <Button onClick={() => setIsModalOpen(true)} className="bg-gradient-to-r from-purple-300 to-buttonSecondary rounded-3xl px-10 py-4 text-black mt-10">
                        CONNECT WALLET
                        </Button>
                    </div>
                    <WalletConnectModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onConnect={handleConnect} />
                </div>
            </div>
        </div>
    </main>
  );
}
function calculateFee(amount: any): import("react").SetStateAction<number> {
    throw new Error("Function not implemented.");
}

