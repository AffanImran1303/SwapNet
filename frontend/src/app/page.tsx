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
import swapToken from "../../public/arrow-up-arrow-down.svg"
import Image from "next/image";
import {useState} from "react";
export default function Home() {
    const [fromToken, setFromToken] = useState("");
    const [fromAmount, setFromAmount] = useState("");

    const [toAmount, setToAmount] = useState("");
    const [toToken, setToToken] = useState("");

    function handleFromAmount(e){
        e.preventDefault()
        setFromAmount(e.target.value)
    }

    function handleToAmount(e) {
        e.preventDefault()
        setToAmount(e.target.value)
    }
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24 bg-gradient-to-t from-bgPrimary to-bgSecondary">
      <NavBar/>
        <div className="text-[#F0D6FF] p-4 space-y-6 w-full max-w-3xl mt-4">
            <div className="flex gap-4">
                <span>From :</span>
                <div className="flex flex-col">
                    <Select>
                        <SelectTrigger className="text-[#F0D6FF] bg-bgSecondary w-[140px] h-[30px] rounded-full border-0">
                            <SelectValue placeholder="Select a token" />
                        </SelectTrigger>
                        <SelectContent className={'bg-bgSecondary text-[#F0D6FF] border-0'}>
                            <SelectItem value="Ethereum" className='text-[#F0D6FF] bg-bgSecondary border-0'>Ethereun</SelectItem>
                            <SelectItem value="Binance" className='text-[#F0D6FF] bg-bgSecondary border-0'>Binance</SelectItem>
                            <SelectItem value="Solana" className='text-[#F0D6FF] bg-bgSecondary border-0'>Solana</SelectItem>
                        </SelectContent>
                    </Select>
                    <div className="w-[604px] h-[102px] rounded-lg flex bg-[#3E2F4C] my-2 items-center">
                        <div className='w-4/5'>
                            <Input name='from' placeholder='00.00' className="bg-transparent border-0 h-full text-center text-2xl font-bold text-gray-500" onChange={handleFromAmount}
                                   value={fromAmount}/>
                            <div className='bg-transparent border-0 text-center text-sm text-gray-500'>$ {fromAmount ? fromAmount : '00.00'}</div>
                        </div>
                        <Select>
                            <SelectTrigger className="text-[#F0D6FF] w-[133px] bg-bgSecondary h-full border-0">
                                <SelectValue placeholder="TKN" />
                            </SelectTrigger>
                            <SelectContent className={'bg-bgSecondary text-[#F0D6FF] border-0'}>
                                <SelectItem value="Ethereum" className='text-[#F0D6FF] bg-bgSecondary border-0'>ETH</SelectItem>
                                <SelectItem value="Binance" className='text-[#F0D6FF] bg-bgSecondary border-0'>BNB</SelectItem>
                                <SelectItem value="Solana" className='text-[#F0D6FF] bg-bgSecondary border-0'>SOL</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                </div>
            </div>
        </div>
        <Image src={swapToken} alt={'exchange token'} width={48} height={48} className={'cursor-pointer'}/>
        <div className="text-[#F0D6FF] p-4 space-y-6 w-full max-w-3xl mt-4">
            <div className="flex gap-4">
                <span>To :</span>
                <div className="flex flex-col">
                    <Select>
                        <SelectTrigger className="text-[#F0D6FF] bg-bgSecondary w-[140px] h-[30px] rounded-full border-0">
                            <SelectValue placeholder="Select a token" />
                        </SelectTrigger>
                        <SelectContent className={'bg-bgSecondary text-[#F0D6FF] border-0'}>
                            <SelectItem value="Ethereum" className='text-[#F0D6FF] bg-bgSecondary border-0'>Ethereun</SelectItem>
                            <SelectItem value="Binance" className='text-[#F0D6FF] bg-bgSecondary border-0'>Binance</SelectItem>
                            <SelectItem value="Solana" className='text-[#F0D6FF] bg-bgSecondary border-0'>Solana</SelectItem>
                        </SelectContent>
                    </Select>
                    <div className="w-[604px] h-[102px] rounded-lg flex bg-[#3E2F4C] my-2 items-center">
                        <div className='w-4/5'>
                            <Input name='from' placeholder='00.00' className="bg-transparent border-0 h-full text-center text-2xl font-bold text-gray-500" onChange={handleToAmount}
                                   value={toAmount}/>
                            <div className='bg-transparent border-0 text-center text-sm text-gray-500'>$ {toAmount ? toAmount : '00.00'}</div>
                        </div>
                        <Select>
                            <SelectTrigger className="text-[#F0D6FF] w-[133px] bg-bgSecondary h-full border-0">
                                <SelectValue placeholder="TKN" />
                            </SelectTrigger>
                            <SelectContent className={'bg-bgSecondary text-[#F0D6FF] border-0'}>
                                <SelectItem value="Ethereum" className='text-[#F0D6FF] bg-bgSecondary border-0'>ETH</SelectItem>
                                <SelectItem value="Binance" className='text-[#F0D6FF] bg-bgSecondary border-0'>BNB</SelectItem>
                                <SelectItem value="Solana" className='text-[#F0D6FF] bg-bgSecondary border-0'>SOL</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                </div>
            </div>
        </div>
    </main>
  );
}
