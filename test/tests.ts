import { expect, should } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Tests", function () {
    async function deploymentFiture() {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();

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
        const hreBasedToken = await BasedToken.deploy();
       
        return {
            hreSimepleERCFund, 
            hreTimeLock, 
            hreBasedToken, 
            owner, 
            addr1, 
            addr2,
            addr3
        }
    }
  
    it("Based Burnable ERC20 Token", async function () {
        const { hreBasedToken, owner , addr1, addr2, addr3} = await loadFixture(deploymentFiture);

        // init mint
        expect(await hreBasedToken.name()).to.equal("BASED");
        expect(await hreBasedToken.symbol()).to.equal("BASED");
        expect(await hreBasedToken.operator()).to.equal(owner.address);
        expect(await hreBasedToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("5000"));

        // mint burnFrom
        await hreBasedToken.mint(addr1.address, ethers.utils.parseEther("12"));
        expect(await hreBasedToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("12"));
        await expect(hreBasedToken.burnFrom(addr1.address, ethers.utils.parseEther("10"))).to.be.revertedWith('ERC20: insufficient allowance');
        await hreBasedToken.connect(addr1).approve(owner.address, ethers.utils.parseEther("13"));
        await hreBasedToken.connect(owner).burnFrom(addr1.address, ethers.utils.parseEther("10"));
        expect(await hreBasedToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("2"));

        // mint & burn
        expect(await hreBasedToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("5000"));
        await hreBasedToken.mint(owner.address, ethers.utils.parseEther("15"));
        expect(await hreBasedToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("5015"));
        await hreBasedToken.burn(ethers.utils.parseEther("15"));
        expect(await hreBasedToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("5000"));

        // TODO: basedOracle setBasedOracle 
        // but _getBasedPrice is internal, seems not be used in this project

        // distributeReward
        const INIT_GENSIS_POOL = "27500";
        const INIT_DAPFUND = "1000";
        await hreBasedToken.distributeReward(addr2.address, addr3.address);
        expect(await hreBasedToken.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther(INIT_GENSIS_POOL));
        expect(await hreBasedToken.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther(INIT_DAPFUND));
        await expect(hreBasedToken.distributeReward(addr2.address, addr3.address)).to.be.revertedWith('only can distribute once');
    });
});