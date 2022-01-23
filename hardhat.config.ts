import { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy-fake-erc20";
import "@nomiclabs/hardhat-etherscan";
import  "dotenv/config";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{ version: "0.8.7", settings: {
        optimizer: {
          enabled: true,
          runs: 50,
        },
      } }],
  },

  networks: {
    fantom: {
      url: 'https://rpc.testnet.fantom.network/',
      accounts: [`${process.env.METAMASK_KEY}`]
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.RINKEBY_API_KEY}`,
      accounts: [`${process.env.METAMASK_KEY}`]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      ftmTestnet: process.env.FTMSCAN_API_KEY,
      rinkeby: process.env.ETHERSCAN_API_KEY,
    }
  },
};

export default config;