// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import {ethers} from 'hardhat';
import 'dotenv/config';
const hre = require('hardhat');
import contractArgsMap from './contractArgs';

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const [deployer] = await ethers.getSigners();

    console.log(`Deploying contracts with the account: ${deployer.address}`);
    const balance = await deployer.getBalance();
    console.log(`Account balance: ${balance.toString()}`);

    const deployedContract: string = 'Greeter';
    const deployNetwork: string = 'Rinkeby';
    let deployedContractArgs: any = contractArgsMap.get(deployedContract);

    const Constract = await ethers.getContractFactory(deployedContract);
    const contract = await Constract.deploy(...deployedContractArgs);
    await contract.deployed();
    console.log(`Token address: ${contract.address}`);

/*
    // 3 sec wait
    await new Promise((resolve) => setTimeout(resolve, 3000));

    // Verify contract
    await hre.run('verify:verify', {
        address: contract.address,
        constructorArguments: [...deployedContractArgs],
        network: deployNetwork,
        apiKey: {
            ftmTestnet: process.env.FTMSCAN_API_KEY,
            rinkeby: process.env.ETHERSCAN_API_KEY,
        },
    });
*/
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
