import { expect, should } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Tests", function () {
    async function deploymentFiture() {
        const [owner, addr1, addr2] = await ethers.getSigners();

        /////  Simpek ERC Fund Deploy
        const SimpleERCFund = await ethers.getContractFactory("SimpleERCFund");
        const hreSimepleERCFund = await SimpleERCFund.deploy();
        await hreSimepleERCFund.deployed();
        


        ///// TimeLock
        const one_day_sec = 24*60*60;
        const TimeLock = await ethers.getContractFactory("Timelock");
       // expect(await TimeLock.deploy(owner.address, one_day_sec - 10)).rejectedWith("Timelock::constructor: Delay must exceed minimum delay.");
        // expect(await TimeLock.deploy(owner.address, one_day_sec - 10)).to.be.rejected;
        const hreTimeLock = await TimeLock.deploy(owner.address, one_day_sec);
        await hreTimeLock.deployed();

        ///// BasedToken
        const BasedToken = await ethers.getContractFactory("Based");
        const 

        
        return {hreSimepleERCFund, owner, addr1, addr2}
    }
  
    it("Simple ERC Fund", async function () {
        const { hardhatToken, owner } = await loadFixture(deploymentFiture);

    });
});