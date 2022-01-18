// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

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

  const Based = await ethers.getContractFactory("Based");
  const based = await Based.deploy(0, "0x1252E3f03E0caa840cbb35442d817a1686A62586");
  await based.deployed();

  console.log(`Token address: ${based.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
