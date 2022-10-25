import { expect, should } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Tests", function () {
    async function deploymentFixture() {
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
        await hreBasedToken.deployed();

        ///// BBondToken
        const BBondToken = await ethers.getContractFactory("BBond");
        const hreBBondToken = await BBondToken.deploy();
        await hreBBondToken.deployed();

        ///// BShareToken
        const BShareToken = await ethers.getContractFactory("BShare");
        const hreBShareToken = await BShareToken.deploy();
        await hreBShareToken.deployed();

        return {
            hreSimepleERCFund, 
            hreTimeLock, 
            hreBasedToken,
            hreBBondToken,
            hreBShareToken,
            owner, 
            addr1, 
            addr2,
            addr3
        }


    }
  
    it("Based Burnable ERC20 Token", async function () {
        const { hreBasedToken, owner , addr1, addr2, addr3} = await loadFixture(deploymentFixture);

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

        // distributeReward only be called once
        const INIT_GENSIS_POOL = "27500";
        const INIT_DAPFUND = "1000";
        await hreBasedToken.distributeReward(addr2.address, addr3.address);
        expect(await hreBasedToken.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther(INIT_GENSIS_POOL));
        expect(await hreBasedToken.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther(INIT_DAPFUND));
        await expect(hreBasedToken.distributeReward(addr2.address, addr3.address)).to.be.revertedWith('only can distribute once');
    });

    it("BBond Burnable ERC20 Token", async function () {
        const { hreBBondToken, owner , addr1, addr2, addr3} = await loadFixture(deploymentFixture);

        // no init mint
        expect(await hreBBondToken.name()).to.equal("BBOND");
        expect(await hreBBondToken.symbol()).to.equal("BBOND");
        expect(await hreBBondToken.operator()).to.equal(owner.address);
        expect(await hreBBondToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("0"));

        // mint burnFrom
        await hreBBondToken.mint(addr1.address, ethers.utils.parseEther("12"));
        expect(await hreBBondToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("12"));
        await expect(hreBBondToken.burnFrom(addr1.address, ethers.utils.parseEther("10"))).to.be.revertedWith('ERC20: insufficient allowance');
        await hreBBondToken.connect(addr1).approve(owner.address, ethers.utils.parseEther("13"));
        await hreBBondToken.connect(owner).burnFrom(addr1.address, ethers.utils.parseEther("10"));
        expect(await hreBBondToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("2"));
        
        // mint & burn
        await hreBBondToken.mint(owner.address, ethers.utils.parseEther("15"));
        expect(await hreBBondToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("15"));
        await hreBBondToken.burn(ethers.utils.parseEther("15"));
        expect(await hreBBondToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("0"));
    });

    it("BShare Burnable ERC20 Token", async function () {
        const { hreBShareToken, owner , addr1, addr2, addr3} = await loadFixture(deploymentFixture);

        // init mint
        expect(await hreBShareToken.name()).to.equal("BSHARE");
        expect(await hreBShareToken.symbol()).to.equal("BSHARE");
        expect(await hreBShareToken.operator()).to.equal(owner.address);
        expect(await hreBShareToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("10"));
      
        // burn (cannot mint)
        await hreBShareToken.burn(ethers.utils.parseEther("1"));
        expect(await hreBShareToken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("9"));

        // distributeReward only be called once
        const FARMING_POOL_REWARD_ALLOC = "50000";
        await hreBShareToken.distributeReward(addr1.address);
        expect(await hreBShareToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther(FARMING_POOL_REWARD_ALLOC));
        await expect(hreBShareToken.distributeReward(addr1.address)).to.be.revertedWith('only can distribute once');

        // burnFrom (cannot mint)
        await hreBShareToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("1"));
        expect(await hreBShareToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("49999"));
        await hreBShareToken.connect(addr1).approve(owner.address, ethers.utils.parseEther(FARMING_POOL_REWARD_ALLOC));
        await hreBShareToken.connect(owner).burnFrom(addr1.address, ethers.utils.parseEther("49999"));
        expect(await hreBShareToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("0"));
    });
});