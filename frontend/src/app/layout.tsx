import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
// import { config } from '@fortawesome/fontawesome-svg-core'
// import '@fortawesome/fontawesome-svg-core/styles.css'
// config.autoAddCss = false
import { headers } from "next/headers"
import Providers from "./providers"

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Swapnet",
  description: "Generated by create next app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookie = headers().get("cookie");
  
  return (
    <html lang="en">
      <body className={inter.className}><Providers cookie={cookie}>{children}</Providers></body>
    </html>
  );
}
