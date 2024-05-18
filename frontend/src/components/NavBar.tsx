import { Button } from "@/components/ui/button";
import Link from "next/link";

export default function NavBar() {
    return (
        <header className="flex justify-between items-center w-full">
            <span>[ LOGO ]</span>
            <Button asChild className={'w-[142px] h-[40px] bg-buttonPrimary rounded-[8px] text-white'}>
                <Link href="#">Connect wallet</Link>
            </Button>
        </header>
    )
}