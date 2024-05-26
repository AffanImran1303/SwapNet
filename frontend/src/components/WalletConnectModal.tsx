import React from 'react';
import Image from 'next/image';
import metaMask from '../../public/walletIcon/metamask.svg';
import phantom from '../../public/phantom-icon.png';
import coinBase from '../../public/walletIcon/coinbase-wallet-logo.svg';
import walletConnect from '../../public/walletIcon/WalletConnectIcon.png';
import trustWallet from '../../public/walletIcon/trust-wallet-logo.svg';
import uniSwap from '../../public/walletIcon/uniswap-logo.png';

const WalletConnectModal = ({ isOpen, onClose, onConnect }) => {
    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
            <div className="bg-bgSecondary p-5 px-10 rounded-lg">
                <button onClick={() => onConnect('Metamask')} className="block w-full p-3 text-left hover:opacity-60">
                    <Image src={metaMask} alt="metamask" width={24} height={24} className="inline-block mr-2" />
                    Metamask
                </button>
                <button onClick={() => onConnect('Phantom')} className="block w-full p-3 text-left hover:opacity-60">
                    <Image src={phantom} alt="Phantom" width={24} height={24} className="inline-block mr-2" />
                    Phantom
                </button>
                <button onClick={() => onConnect('Coinbase Wallet')} className="block w-full p-3 text-left hover:opacity-60">
                    <Image src={coinBase} alt="CoinBase" width={24} height={24} className="inline-block mr-2" />
                    Coinbase Wallet
                </button>
                <button onClick={() => onConnect('WalletConnect')} className="block w-full p-3 text-left hover:opacity-60">
                    <Image src={walletConnect} alt="WalletConnect" width={24} height={24} className="inline-block mr-2" />
                    WalletConnect
                </button>
                <button onClick={() => onConnect('Trust Wallet')} className="block w-full p-3 text-left hover:opacity-60">
                    <Image src={trustWallet} alt="Trust Wallet" width={24} height={24} className="inline-block mr-2" />
                    Trust Wallet
                </button>
                <button onClick={() => onConnect('UniSwap Wallet')} className="block w-full p-3 text-left hover:opacity-60">
                    <Image src={uniSwap} alt="UniSwap Wallet" width={24} height={24} className="inline-block mr-2" />
                    Uniswap Wallet
                </button>
                <button onClick={onClose} className="mt-4 p-2 text-red-500 hover:text-red-700">Cancel</button>
            </div>
        </div>
    );
};

export default WalletConnectModal;
