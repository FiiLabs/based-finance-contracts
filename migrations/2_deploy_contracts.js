// const Distributor = artifacts.require("Distributor");
const DummyToken = artifacts.require("DummyToken");
const Masonry = artifacts.require("Masonry");
// const Oracle = artifacts.require("Oracle");
const SimpleERCFund = artifacts.require("SimpleERCFund");
const TBond = artifacts.require("TBond");
const TaxOffice = artifacts.require("TaxOffice");
// const TaxOfficeV2 = artifacts.require("TaxOfficeV2");
// const TaxOracle = artifacts.require("TaxOracle");
const Timelock = artifacts.require("Timelock");
const Tomb = artifacts.require("Tomb");
const Treasury = artifacts.require("Treasury");
const TShare = artifacts.require("TShare");

module.exports = async function(deployer, _taxRate, _taxCollectorAddress) {
  // deploy Tomb contract
  await deployer.deploy(DummyToken);

  // deploy Masonry contract
  await deployer.deploy(Masonry);

  // deploy SimpleERCFund contract
  await deployer.deploy(SimpleERCFund);

  // deploy Tomb contract
  await deployer.deploy(Tomb, 1000, process.env.TAXCOLLECTORADR);
  const tomb = await Tomb.deployed()

  // deploy TaxOffice contract
  await deployer.deploy(TaxOffice, tomb.address);
/*
  // deploy TaxOracle contract
  await deployer.deploy(TaxOracle, tomb.address, );
*/
  // deploy TBond contract
  await deployer.deploy(TBond);

  // deploy Timelock contract
  await deployer.deploy(Timelock, process.env.ADMIN, 86400 /*2 days in seconds*/);

/*  // deploy Treasury contract
  await deployer.deploy(Treasury);*/

  // deploy TShare contract
  await deployer.deploy(TShare, 1642112616142, process.env.COMMUNITYFUND, process.env.DEVFUND)
};
