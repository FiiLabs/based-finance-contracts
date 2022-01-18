import { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy-fake-erc20";
import "@nomiclabs/hardhat-etherscan";
import  "dotenv/config";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{ version: "0.8.7", settings: {} }],
  },

  networks: {
    fantom: {
      url: 'https://rpc.testnet.fantom.network/',
      accounts: [`${process.env.METAMASK_KEY}`]
    },
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_RINKEBY_API_KEY}`,
      accounts: [`${process.env.METAMASK_KEY}`]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${process.env.ETHERSCAN_API_KEY}`
  },
};

export default config;