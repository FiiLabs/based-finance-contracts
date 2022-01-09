const Tomb = artifacts.require("Tomb");

module.exports = async function (deployer, network, accounts) {
  // Deploy Tomb Contract
  await deployer.deploy(Tomb);
  const tomb = await Tomb.deployed();

  // Transfer all RWD tokens to Decentral Bank
  //await rwd.transfer(decentralBank.address, "1000000000000000000000000");

  // Distribute 100 tether tokens to investor
  //await tomb.transfer(accounts[1], "100000000000000000000");
};
