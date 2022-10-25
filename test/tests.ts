import { expect } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Tests", function () {
    async function deploymentFiture() {
        const SimpleERCFund = await ethers.getContractFactory("SimpleERCFund");
        const [owner, addr1, addr2] = await ethers.getSigners();

        const hreSimepleERCFund = await SimpleERCFund.deploy();
        await hreSimepleERCFund.deployed();
        
        return {hreSimepleERCFund, owner, addr1, addr2}
    }
  
    it("Should return the new greeting once it's changed", async function () {
        const { hardhatToken, owner } = await loadFixture(deploymentFiture);

    });
});