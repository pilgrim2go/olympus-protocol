var Core = artifacts.require("./price/PriceProvider.sol");
// var StrategyProvider = artifacts.require("./strategy/StrategyProvider");
// var ExchangeProvider = artifacts.require("./exchange/ExchangeProvider.sol");
// var PriceProvider = artifacts.require("./price/PriceProvider.sol");

module.exports = function (deployer) {
  deployer.deploy(PriceOracle);
  // deployer.deploy(StrategyProvider);
  // deployer.deploy(ExchangeProvider);
  // deployer.deploy(PriceProvider);
};
