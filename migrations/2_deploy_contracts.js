//const Distributor = artifacts.require("Distributor");
//const DummyToken = artifacts.require("DummyToken");
//const Masonry = artifacts.require("Masonry");
//const Migrations = artifacts.require("Migrations");
//const Oracle = artifacts.require("Oracle");
//const SimpleERCFund = artifacts.require("SimpleERCFund");
//const TShare = artifacts.require("TShare");
//const TBond = artifacts.require("TBond");
//const TaxOffice = artifacts.require("TaxOffice");
//const TaxOfficeV2 = artifacts.require("TaxOfficeV2");
//const TaxOracle = artifacts.require("TaxOracle");
//const Timelock = artifacts.require("Timelock");
const Tomb = artifacts.require("Tomb");
//const Treasury = artifacts.require("Treasury");

module.exports = async function(deployer, _taxRate, _taxCollectorAddress) {
  // Deploy Distributor Contract
  await deployer.deploy(Tomb, 1000, "0x1dB3720E5B5AD9B7F05E49f3DeBA2eaB6afD293c");
  const tomb = await Tomb.deployed();
};
