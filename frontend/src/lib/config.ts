'use client';

import { http, createStorage, cookieStorage } from 'wagmi'
import { 
   mainnet,
	polygon,
	optimism,
	arbitrum,
	goerli,
	polygonMumbai,
	optimismGoerli,
	arbitrumGoerli,
	polygonZkEvm,
	polygonZkEvmTestnet,
	sepolia,
	avalancheFuji,
} from 'wagmi/chains'
import { Chain, getDefaultConfig, RainbowKitProvider } from '@rainbow-me/rainbowkit'
import { WagmiProvider } from 'wagmi';
import {
   QueryClientProvider,
   QueryClient,
 } from "@tanstack/react-query";

const projectId = `ad6114001e58e78984164878debc17fe`;

const supportedChains: Chain[] = [
   mainnet,
	polygon,
	optimism,
	arbitrum,
	goerli,
	polygonMumbai,
	optimismGoerli,
	arbitrumGoerli,
	polygonZkEvm,
	polygonZkEvmTestnet,
	sepolia,
	avalancheFuji,
];

export const config = getDefaultConfig({
   appName: 'SwapNet',
   projectId,
   chains: supportedChains as any,
   ssr: true,
   storage: createStorage({
    storage: cookieStorage,
   }),
  transports: supportedChains.reduce((obj, chain) => ({ ...obj, [chain.id]: http() }), {})
 });