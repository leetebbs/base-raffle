import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  webpack: (config) => {
    config.externals.push("pino-pretty", "lokijs", "encoding");
    return config;
  },
  // Enable source maps in development
  productionBrowserSourceMaps: true,
  images: {
    domains: [
      'ipfs.io',
      'ipfs.infura.io',
      'gateway.pinata.cloud',
      'nft-cdn.alchemy.com',
      // ... any other allowed domains
    ],
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  // Add headers configuration
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin',
          },
          {
            key: 'Cross-Origin-Embedder-Policy',
            value: 'require-corp',
          },
        ],
      },
    ];
  },
};

export default nextConfig;
