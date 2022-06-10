require('@nomiclabs/hardhat-ethers');
require('dotenv').config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.13',
    settings: {
      optimizer: {
        enabled: true,
        runs: 4294967295
      }
    }
  },
  networks: {
    brise_mainnet: {
      url: 'https://chainrpc.com',
      accounts: [process.env.PRIVATE_KEY],
      timeout: 70000,
      chainId: 32520
    },
    binance_mainnet: {
      url: 'https://bsc-dataseed1.binance.org',
      accounts: [process.env.PRIVATE_KEY],
      timeout: 70000,
      chainId: 56
    },
    avalanche_mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      accounts: [process.env.PRIVATE_KEY],
      timeout: 70000,
      chainId: 43114
    },
    clover_mainnet: {
      url: 'https://api-para.clover.finance',
      accounts: [process.env.PRIVATE_KEY],
      timeout: 70000,
      chainId: 1024
    },
    matic_mainnet: {
      url: 'https://polygon-rpc.com/',
      accounts: [process.env.PRIVATE_KEY],
      timeout: 70000,
      chainId: 137
    }
  },
  paths: {
    sources: './contracts',
    artifacts: './build'
  }
};
