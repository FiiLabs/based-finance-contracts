import {HardhatUserConfig} from 'hardhat/types';
import 'hardhat-deploy-fake-erc20';
import 'dotenv/config';

import '@nomicfoundation/hardhat-toolbox'; 

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            // for based
            // {
            //     version: '0.8.9',
            //     settings: {
            //         optimizer: {
            //             enabled: true,
            //             runs: 50,
            //         },
            //     },
            // },
            
            // for compound
            {
                version: '0.5.17',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 50,
                    },
                },
            }
        ],
    },

    paths: {
        // sources: "./contracts",
        // tests: "./test",
        sources: "./compound-contracts",
        tests: "./compound-tests",
        cache: "./cache",
        artifacts: "./artifacts"
    },

    networks: {
        fantom: {
            //url: 'https://rpc.testnet.fantom.network/',
            url: 'https://rpc.ftm.tools/',
            accounts: [`${process.env.METAMASK_KEY}`],
            // gasMultiplier: 2,
        },
        rinkeby: {
            url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.RINKEBY_API_KEY}`,
            accounts: [`${process.env.METAMASK_KEY}`],
        },
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: {
            opera: process.env.FTMSCAN_API_KEY,
            rinkeby: process.env.ETHERSCAN_API_KEY,
        },
    },
};

export default config;
