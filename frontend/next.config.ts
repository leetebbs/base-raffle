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
      'nft-cdn.alchemy.com',
      // ... any other allowed domains
    ],
  },
};

export default nextConfig;
