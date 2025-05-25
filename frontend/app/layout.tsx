import type React from "react"
import "@/app/globals.css"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { ThemeProvider } from "@/components/theme-provider"
import { headers } from 'next/headers'
import ContextProvider from '@/context'

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const headersObj = await headers();
  const cookies = headersObj?.get('cookie') || '';

  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <title>NFT Raffle Platform</title>
        <meta name="description" content="Raffle your NFTs or win rare digital assets" />
      </head>
      <body className="min-h-screen bg-black font-sans text-slate-50 antialiased">
        <ThemeProvider defaultTheme="dark">
          <ContextProvider cookies={cookies}>
            <Navbar />
            {children}
            <Footer />
          </ContextProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}
