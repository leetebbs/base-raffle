import { cookieStorage, createStorage, http } from '@wagmi/core'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { base, baseSepolia } from '@reown/appkit/networks'
import { Alchemy, Network } from 'alchemy-sdk';

export const projectId = process.env.NEXT_PUBLIC_PROJECT_ID
export const baseSepoliaContractAddress = process.env.NEXT_PUBLIC_BASE_SEPOLIA_CONTRACT_ADDRESS
const alchemyApiKey = process.env.NEXT_PUBLIC_ALCHEMY_APIKEY
const pId = process.env.NEXT_PUBLIC_PROJECT_ID

// Alchemy configuration
const settings = {
  apiKey: pId,
  network: Network.BASE_SEPOLIA,
  maxRetries: 3,
  requestTimeout: 10000,
  batchRequests: false,
  connectionInfoOverrides: {
    url: `https://base-sepolia.g.alchemy.com/v2/${alchemyApiKey}`,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  },
};

// if (!process.env.NEXT_PUBLIC_ALCHEMY_API_KEY) {
//   throw new Error('Alchemy API key is not defined in environment variables');
// }

export const alchemy = new Alchemy(settings);

if (!projectId) {
  throw new Error('Project ID is not defined')
}

export const networks = [baseSepolia]

// Set up the Wagmi Adapter (Config)
export const wagmiAdapter = new WagmiAdapter({
  storage: createStorage({
    storage: cookieStorage
  }),
  ssr: true,
  projectId,
  networks
})

export const config = wagmiAdapter.wagmiConfig