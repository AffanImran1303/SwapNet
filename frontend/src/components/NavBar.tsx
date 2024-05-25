import { Button } from "@/components/ui/button";
import Link from "next/link";
import Image from "next/image";
import swapnetLogo from "../../public/SWAPNET.png";

export default function NavBar() {
    return (
        <header className="flex justify-between items-center w-full p-4 bg-transparent">
            <span>
                <Image src={swapnetLogo} alt='swapnet logo' width={300} height={40} />
            </span>
            <Button asChild className={'w-[142px] h-[40px] bg-buttonPrimary rounded-[8px] text-white'}>
                <Link href="#">Connect wallet</Link>
            </Button>
        </header>
    )
}