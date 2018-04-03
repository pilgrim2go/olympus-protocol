var Migrations = artifacts.require("./price/PriceProvider.sol");

module.exports = function(deployer) {
  deployer.deploy(PriceProvider);
};
