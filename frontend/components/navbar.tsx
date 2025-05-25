"use client"

import { useState } from "react"
import Link from "next/link"
import { WalletConnect } from "@/components/wallet-connect"
import { Menu, X } from "lucide-react"

export function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 w-full border-b border-slate-800 bg-black/80 backdrop-blur-sm">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        <Link href="/" className="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="none"
            stroke="url(#gradient)"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mr-2"
          >
            <defs>
              <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#a855f7" />
                <stop offset="100%" stopColor="#ec4899" />
              </linearGradient>
            </defs>
            <path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z" />
            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
            <line x1="12" y1="17" x2="12.01" y2="17" />
          </svg>
          <span className="text-xl font-bold">NFTRaffle</span>
        </Link>

        <nav className="hidden md:flex md:items-center md:gap-6">
          <Link href="/" className="text-sm font-medium text-slate-200 transition-colors hover:text-white">
            Home
          </Link>
          <Link href="/create" className="text-sm font-medium text-slate-200 transition-colors hover:text-white">
            Create
          </Link>
          <Link href="/raffles" className="text-sm font-medium text-slate-200 transition-colors hover:text-white">
            Browse
          </Link>
          <Link href="/my-raffles" className="text-sm font-medium text-slate-200 transition-colors hover:text-white">
            My Raffles
          </Link>
        </nav>

        <div className="hidden md:block">
          <WalletConnect />
        </div>

        <button className="block rounded-md p-2 text-slate-400 md:hidden" onClick={() => setIsMenuOpen(!isMenuOpen)}>
          {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </div>

      {/* Mobile menu */}
      {isMenuOpen && (
        <div className="container mx-auto px-4 pb-4 md:hidden">
          <nav className="flex flex-col space-y-4">
            <Link
              href="/"
              className="rounded-md px-3 py-2 text-sm font-medium text-slate-200 hover:bg-slate-800"
              onClick={() => setIsMenuOpen(false)}
            >
              Home
            </Link>
            <Link
              href="/create"
              className="rounded-md px-3 py-2 text-sm font-medium text-slate-200 hover:bg-slate-800"
              onClick={() => setIsMenuOpen(false)}
            >
              Create
            </Link>
            <Link
              href="/raffles"
              className="rounded-md px-3 py-2 text-sm font-medium text-slate-200 hover:bg-slate-800"
              onClick={() => setIsMenuOpen(false)}
            >
              Browse
            </Link>
            <Link
              href="/my-raffles"
              className="rounded-md px-3 py-2 text-sm font-medium text-slate-200 hover:bg-slate-800"
              onClick={() => setIsMenuOpen(false)}
            >
              My Raffles
            </Link>
            <div className="pt-2">
              <WalletConnect />
            </div>
          </nav>
        </div>
      )}
    </header>
  )
}
