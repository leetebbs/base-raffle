import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, CheckCircle, Clock, AlertCircle, HelpCircle, Wallet, Ticket, Trophy } from "lucide-react"

export default function DocsPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-black to-slate-900 py-12">
      <div className="container mx-auto px-4">
        <Link href="/" className="mb-8 inline-flex items-center text-purple-400 hover:text-purple-300">
          <ArrowLeft className="mr-2 h-4 w-4" /> Back to home
        </Link>

        <div className="mx-auto max-w-4xl">
          {/* Hero Section */}
          <div className="mb-12 text-center">
            <h1 className="mb-6 bg-gradient-to-r from-purple-400 via-pink-500 to-amber-500 bg-clip-text text-4xl font-extrabold text-transparent md:text-5xl">
              Raffle Your NFTs. Win Rare Digital Assets.
            </h1>
            <p className="text-lg text-slate-300 md:text-xl">
              Connect your wallet, create or enter raffles using verified NFTs. Transparent, secure, and fun.
            </p>
          </div>

          {/* What is NFT Raffle */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-4 text-2xl font-bold text-white">What is NFT Raffle?</h2>
              <p className="mb-6 text-slate-300">
                NFT Raffle is a fun and fair way to win NFTs! Think of it like a digital raffle where you can win
                amazing NFTs by buying tickets.
              </p>
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-purple-600">
                    <Ticket className="h-5 w-5 text-white" />
                  </div>
                  <p className="text-sm text-slate-300">Create your own NFT raffle and set your own rules</p>
                </div>
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-pink-600">
                    <Wallet className="h-5 w-5 text-white" />
                  </div>
                  <p className="text-sm text-slate-300">Buy tickets to enter other people's raffles</p>
                </div>
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-amber-600">
                    <Trophy className="h-5 w-5 text-white" />
                  </div>
                  <p className="text-sm text-slate-300">Win NFTs through a fair and random selection process</p>
                </div>
                <div className="rounded-lg bg-slate-700/30 p-4">
                  <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-green-600">
                    <CheckCircle className="h-5 w-5 text-white" />
                  </div>
                  <p className="text-sm text-slate-300">
                    Get your money back if a raffle doesn't get enough participants
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* How to Create a Raffle */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-6 text-2xl font-bold text-white">How to Create a Raffle</h2>

              <div className="mb-8">
                <h3 className="mb-3 text-xl font-semibold text-purple-400">Step 1: Choose Your NFT</h3>
                <p className="text-slate-300">
                  Select the NFT you want to raffle off. You'll need to approve the transfer of your NFT to our
                  platform.
                </p>
              </div>

              <div>
                <h3 className="mb-3 text-xl font-semibold text-purple-400">Step 2: Set Up Your Raffle</h3>
                <p className="mb-4 text-slate-300">Decide on these important details:</p>
                <ul className="space-y-2 text-slate-300">
                  <li className="flex items-start">
                    <CheckCircle className="mr-2 mt-0.5 h-4 w-4 text-green-400" />
                    How many tickets you want to sell
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="mr-2 mt-0.5 h-4 w-4 text-green-400" />
                    How much each ticket should cost
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="mr-2 mt-0.5 h-4 w-4 text-green-400" />
                    How long the raffle should run (between 1 day and 14 days)
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="mr-2 mt-0.5 h-4 w-4 text-green-400" />
                    The minimum number of tickets that need to be sold for the raffle to happen
                  </li>
                </ul>
              </div>
            </CardContent>
          </Card>

          {/* How to Join a Raffle */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-6 text-2xl font-bold text-white">How to Join a Raffle</h2>

              <div className="mb-8">
                <h3 className="mb-3 text-xl font-semibold text-purple-400">Buying Tickets</h3>
                <ol className="space-y-3 text-slate-300">
                  <li className="flex items-start">
                    <span className="mr-3 flex h-6 w-6 items-center justify-center rounded-full bg-purple-600 text-sm font-bold text-white">
                      1
                    </span>
                    Browse available raffles and find one you like
                  </li>
                  <li className="flex items-start">
                    <span className="mr-3 flex h-6 w-6 items-center justify-center rounded-full bg-purple-600 text-sm font-bold text-white">
                      2
                    </span>
                    Choose how many tickets you want to buy (you can buy up to 100 at a time)
                  </li>
                  <li className="flex items-start">
                    <span className="mr-3 flex h-6 w-6 items-center justify-center rounded-full bg-purple-600 text-sm font-bold text-white">
                      3
                    </span>
                    Pay for your tickets using ETH
                  </li>
                  <li className="flex items-start">
                    <span className="mr-3 flex h-6 w-6 items-center justify-center rounded-full bg-purple-600 text-sm font-bold text-white">
                      4
                    </span>
                    Remember, buying more tickets increases your chances of winning!
                  </li>
                </ol>
              </div>

              <div>
                <h3 className="mb-3 text-xl font-semibold text-purple-400">What Happens Next?</h3>
                <p className="mb-4 text-slate-300">
                  When the raffle ends, our system automatically picks a winner using a fair random selection process
                  that can't be tampered with. If you are the lucky winner, you'll automatically receive:
                </p>
                <ul className="space-y-2 text-slate-300">
                  <li className="flex items-start">
                    <Trophy className="mr-2 mt-0.5 h-4 w-4 text-amber-400" />
                    The awesome NFT you entered to win
                  </li>
                  <li className="flex items-start">
                    <Trophy className="mr-2 mt-0.5 h-4 w-4 text-amber-400" />A portion of the total money collected from
                    ticket sales (this is the prize pool, and a small fee is taken out for the platform)
                  </li>
                </ul>
              </div>
            </CardContent>
          </Card>

          {/* Understanding Raffle Status */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-6 text-2xl font-bold text-white">Understanding Raffle Status</h2>
              <p className="mb-6 text-slate-300">Here's what the different statuses mean:</p>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="rounded-lg bg-green-900/30 border border-green-700/50 p-4">
                  <div className="mb-2 flex items-center">
                    <CheckCircle className="mr-2 h-5 w-5 text-green-400" />
                    <span className="font-semibold text-green-400">Open</span>
                  </div>
                  <p className="text-sm text-slate-300">The raffle is active and you can still buy tickets.</p>
                </div>

                <div className="rounded-lg bg-yellow-900/30 border border-yellow-700/50 p-4">
                  <div className="mb-2 flex items-center">
                    <Clock className="mr-2 h-5 w-5 text-yellow-400" />
                    <span className="font-semibold text-yellow-400">Ended</span>
                  </div>
                  <p className="text-sm text-slate-300">
                    The time for buying tickets is over, and we're waiting for the winner to be selected.
                  </p>
                </div>

                <div className="rounded-lg bg-blue-900/30 border border-blue-700/50 p-4">
                  <div className="mb-2 flex items-center">
                    <Trophy className="mr-2 h-5 w-5 text-blue-400" />
                    <span className="font-semibold text-blue-400">Completed</span>
                  </div>
                  <p className="text-sm text-slate-300">
                    The winner has been chosen, and the NFT and prize money have been sent out.
                  </p>
                </div>

                <div className="rounded-lg bg-red-900/30 border border-red-700/50 p-4">
                  <div className="mb-2 flex items-center">
                    <AlertCircle className="mr-2 h-5 w-5 text-red-400" />
                    <span className="font-semibold text-red-400">Canceled</span>
                  </div>
                  <p className="text-sm text-slate-300">
                    The raffle didn't meet the minimum number of tickets needed, so it was canceled. Everyone who bought
                    a ticket will get a refund.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* If a Raffle is Canceled */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-4 text-2xl font-bold text-white">If a Raffle is Canceled</h2>
              <p className="mb-6 text-slate-300">
                Don't worry! If a raffle doesn't get enough participants by the end time, it will be canceled to protect
                everyone.
              </p>
              <div className="space-y-4">
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">The NFT goes back safely to the person who created the raffle.</p>
                </div>
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">
                    You automatically get all the ETH you spent on tickets back in your wallet.
                  </p>
                </div>
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">No fees are charged for canceled raffles.</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Platform Fees */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-4 text-2xl font-bold text-white">Platform Fees</h2>
              <div className="rounded-lg bg-purple-900/30 border border-purple-700/50 p-6">
                <p className="text-lg text-slate-300">
                  We charge a small fee of <span className="font-bold text-purple-400">10%</span> only when a raffle is
                  successfully completed and a winner is chosen. If a raffle is canceled, you pay nothing extra.
                </p>
              </div>
            </CardContent>
          </Card>

          {/* Getting Started */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-6 text-2xl font-bold text-white">Getting Started</h2>
              <p className="mb-6 text-slate-300">Ready to join the fun? Here's what you need to do:</p>
              <ol className="space-y-4 text-slate-300">
                <li className="flex items-start">
                  <span className="mr-3 flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600 text-sm font-bold text-white">
                    1
                  </span>
                  <div>
                    <p className="font-medium">Connect your crypto wallet (like MetaMask) to our platform.</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="mr-3 flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600 text-sm font-bold text-white">
                    2
                  </span>
                  <div>
                    <p className="mb-2 font-medium">Make sure you have enough ETH in your wallet for:</p>
                    <ul className="ml-4 space-y-1 text-sm">
                      <li>• Buying tickets for raffles you want to enter</li>
                      <li>• Small network transaction fees (called gas fees)</li>
                    </ul>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="mr-3 flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600 text-sm font-bold text-white">
                    3
                  </span>
                  <div>
                    <p className="font-medium">Browse the list of active raffles or create your very own.</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="mr-3 flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-r from-purple-600 to-pink-600 text-sm font-bold text-white">
                    4
                  </span>
                  <div>
                    <p className="font-medium">
                      Buy your tickets and keep an eye on the raffle end time to see if you win!
                    </p>
                  </div>
                </li>
              </ol>
            </CardContent>
          </Card>

          {/* Tips for Success */}
          <Card className="mb-8 bg-slate-800/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <h2 className="mb-6 text-2xl font-bold text-white">Tips for Success</h2>
              <div className="space-y-3">
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">
                    Always carefully read the details of a raffle before you buy tickets.
                  </p>
                </div>
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">Keep track of the raffle end times so you don't miss out.</p>
                </div>
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">
                    Make sure you have enough ETH in your wallet to cover ticket costs and gas fees.
                  </p>
                </div>
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">
                    Check if the raffle has met its minimum ticket requirement – this is important for it to run.
                  </p>
                </div>
                <div className="flex items-start rounded-lg bg-slate-700/30 p-4">
                  <CheckCircle className="mr-3 mt-0.5 h-5 w-5 text-green-400" />
                  <p className="text-slate-300">Verify the current status of a raffle before participating.</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Need Help */}
          <Card className="mb-8 bg-gradient-to-r from-purple-900/50 to-pink-900/50 backdrop-blur-sm">
            <CardContent className="p-8 text-center">
              <HelpCircle className="mx-auto mb-4 h-12 w-12 text-purple-400" />
              <h2 className="mb-4 text-2xl font-bold text-white">Need Help?</h2>
              <p className="mb-6 text-slate-300">
                If you have any questions or run into any issues, we're here for you! You can contact our support team
                directly or check out our Frequently Asked Questions (FAQ) section for quick answers.
              </p>
              <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
                <Link href="/faq">
                  <Button
                    variant="outline"
                    className="border-purple-600 bg-purple-600/20 text-white hover:bg-purple-600/30"
                  >
                    View FAQ
                  </Button>
                </Link>
                <Link href="/contact">
                  <Button className="bg-gradient-to-r from-purple-600 to-pink-600">Contact Support</Button>
                </Link>
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <div className="text-center">
            <h3 className="mb-6 text-xl font-semibold text-white">Ready to get started?</h3>
            <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
              <Link href="/raffles">
                <Button variant="outline" className="border-slate-700 bg-slate-800/50 text-white hover:bg-slate-700">
                  Browse Raffles
                </Button>
              </Link>
              <Link href="/create">
                <Button className="bg-gradient-to-r from-purple-600 to-pink-600">Create a Raffle</Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
