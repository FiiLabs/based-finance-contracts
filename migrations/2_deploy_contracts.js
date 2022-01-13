const Distributor = artifacts.require("Distributor");
const DummyToken = artifacts.require("DummyToken");
const Masonry = artifacts.require("Masonry");
const Migrations = artifacts.require("Migrations");
const Oracle = artifacts.require("Oracle");
const SimpleERCFund = artifacts.require("SimpleERCFund");
const TBond = artifacts.require("TBond");
const TaxOffice = artifacts.require("TaxOffice");
//const TaxOfficeV2 = artifacts.require("TaxOfficeV2");
const TaxOracle = artifacts.require("TaxOracle");
const Timelock = artifacts.require("Timelock");
const Tomb = artifacts.require("Tomb");
const Treasury = artifacts.require("Treasury");
const TShare = artifacts.require("TShare");
/*
module.exports = async function(deployer) {
  // Deploy DummyToken Contract
  await deployer.deploy(DummyToken);
  const tomb = await DummyToken.deployed();
};

module.exports = async function(deployer) {
  // Deploy Masonry Contracts
  await deployer.deploy(Masonry);
  const tomb = await Masonry.deployed();
};

module.exports = async function(deployer) {
  // Deploy Migrations Contract
  await deployer.deploy(Migrations);
  const tomb = await Migrations.deployed();
};

module.exports = async function(deployer) {
  // Deploy Oracle Contract
  await deployer.deploy(Oracle);
  const tomb = await Oracle.deployed();
};

module.exports = async function(deployer) {
  // Deploy Oracle Contract
  await deployer.deploy(Oracle);
  const tomb = await Oracle.deployed();
};

module.exports = async function(deployer) {
  // Deploy SimpleERCFund Contract
  await deployer.deploy(SimpleERCFund);
  const tomb = await SimpleERCFund.deployed();
};

module.exports = async function(deployer) {
  // Deploy TBond Contract
  await deployer.deploy(TBond);
  const tomb = await TBond.deployed();
};

module.exports = async function(deployer) {
  // Deploy TaxOffice Contract
  await deployer.deploy(TaxOffice);
  const tomb = await TaxOffice.deployed();
};

module.exports = async function(deployer) {
  // Deploy TaxOracle Contract
  await deployer.deploy(TaxOracle);
  const tomb = await TaxOracle.deployed();
};

module.exports = async function(deployer) {
  // Deploy Timelock Contract
  await deployer.deploy(Timelock);
  const tomb = await Timelock.deployed();
};*/

module.exports = async function(deployer, _taxRate, _taxCollectorAddress) {
  // Deploy Tomb Contract
  await deployer.deploy(Tomb, 1000, process.env.TAXCOLLECTORADR);
  const tomb = await Tomb.deployed();
};

/*
module.exports = async function(deployer, _taxRate, _taxCollectorAddress) {
  // Deploy Treasury Contract
  await deployer.deploy(Treasury);
  const tomb = await Treasury.deployed();
};

module.exports = async function(deployer) {
  // Deploy TShare Contract
  await deployer.deploy(TShare);
  const tomb = await TShare.deployed();
};
*/

