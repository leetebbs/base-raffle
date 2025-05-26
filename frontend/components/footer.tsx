import Link from "next/link"
import { Github, Twitter, DiscIcon as Discord } from "lucide-react"

export function Footer() {
  return (
    <footer className="border-t border-slate-800 bg-black py-8">
      <div className="container mx-auto px-4">
        <div className="grid gap-8 md:grid-cols-4">
          <div className="md:col-span-1">
            <Link href="/" className="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="url(#footerGradient)"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className="mr-2"
              >
                <defs>
                  <linearGradient id="footerGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stopColor="#a855f7" />
                    <stop offset="100%" stopColor="#ec4899" />
                  </linearGradient>
                </defs>
                <path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z" />
                <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
                <line x1="12" y1="17" x2="12.01" y2="17" />
              </svg>
              <span className="text-lg font-bold">NFTRaffle</span>
            </Link>
            <p className="mt-4 text-sm text-slate-400">
              The premier platform for NFT raffles. Create and participate in raffles for rare digital assets.
            </p>
            <div className="mt-4 flex space-x-4">
              <Link href="#" className="text-slate-400 hover:text-purple-400">
                <Twitter className="h-5 w-5" />
                <span className="sr-only">Twitter</span>
              </Link>
              <Link href="#" className="text-slate-400 hover:text-purple-400">
                <Discord className="h-5 w-5" />
                <span className="sr-only">Discord</span>
              </Link>
              <Link href="#" className="text-slate-400 hover:text-purple-400">
                <Github className="h-5 w-5" />
                <span className="sr-only">GitHub</span>
              </Link>
            </div>
          </div>

          <div className="md:col-span-3">
            <div className="grid grid-cols-2 gap-8 sm:grid-cols-3">
              <div>
                <h3 className="mb-3 text-sm font-semibold uppercase text-white">Platform</h3>
                <ul className="space-y-2">
                  <li>
                    <Link href="/raffles" className="text-sm text-slate-400 hover:text-purple-400">
                      Browse Raffles
                    </Link>
                  </li>
                  <li>
                    <Link href="/create" className="text-sm text-slate-400 hover:text-purple-400">
                      Create a Raffle
                    </Link>
                  </li>
                  <li>
                    <Link href="/my-raffles" className="text-sm text-slate-400 hover:text-purple-400">
                      My Raffles
                    </Link>
                  </li>
                  <li>
                    <Link href="/faq" className="text-sm text-slate-400 hover:text-purple-400">
                      FAQ
                    </Link>
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="mb-3 text-sm font-semibold uppercase text-white">Resources</h3>
                <ul className="space-y-2">
                  <li>
                    <Link href="/docs" className="text-sm text-slate-400 hover:text-purple-400">
                      Documentation
                    </Link>
                  </li>
                  <li>
                    <Link href="/smart-contracts" className="text-sm text-slate-400 hover:text-purple-400">
                      Smart Contracts
                    </Link>
                  </li>
                  <li>
                    <Link href="/api" className="text-sm text-slate-400 hover:text-purple-400">
                      API
                    </Link>
                  </li>
                  <li>
                    <Link href="/security" className="text-sm text-slate-400 hover:text-purple-400">
                      Security
                    </Link>
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="mb-3 text-sm font-semibold uppercase text-white">Legal</h3>
                <ul className="space-y-2">
                  <li>
                    <Link href="/terms" className="text-sm text-slate-400 hover:text-purple-400">
                      Terms of Service
                    </Link>
                  </li>
                  <li>
                    <Link href="/privacy" className="text-sm text-slate-400 hover:text-purple-400">
                      Privacy Policy
                    </Link>
                  </li>
                  <li>
                    <Link href="/cookies" className="text-sm text-slate-400 hover:text-purple-400">
                      Cookie Policy
                    </Link>
                  </li>
                  <li>
                    <Link href="/compliance" className="text-sm text-slate-400 hover:text-purple-400">
                      Compliance
                    </Link>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-8 border-t border-slate-800 pt-8">
          <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
            <p className="text-sm text-slate-500">&copy; {new Date().getFullYear()} NFTRaffle. All rights reserved.</p>
            <p className="text-sm text-slate-500">Powered by Base. Built with ❤️ for the NFT community.</p>
          </div>
        </div>
      </div>
    </footer>
  )
}
