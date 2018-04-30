var Core = artifacts.require("./OlympusLabsCore.sol");
var StrategyProvider = artifacts.require("./strategy/StrategyProvider.sol");
var PermissionProvider = artifacts.require("./permission/PermissionProvider.sol");
var PriceProvider = artifacts.require("./price/PriceProvider.sol");
var ExtendedStorage = artifacts.require("./storage/OlympusStorageExtended.sol")
var OlympusStorage = artifacts.require("./storage/OlympusStorage.sol");
let premissionInstance, coreInstance;

const KyberConfig = require('../scripts/libs/kyber_config');
var KyberNetworkExchange = artifacts.require("KyberNetworkExchange");
var ExchangeAdapterManager = artifacts.require("ExchangeAdapterManager");
var ExchangeProvider = artifacts.require("ExchangeProvider");
var ExchangeProviderWrap = artifacts.require("ExchangeProviderWrap");
var MockKyberNetwork = artifacts.require("MockKyberNetwork");
var SimpleERC20Token = artifacts.require("SimpleERC20Token");
var CentralizedExchange = artifacts.require("CentralizedExchange.sol");
const args = require('../scripts/libs/args')

function deployOnDev(deployer, num) {
  return deployer.then(() => {
    return deployer.deploy(ExchangeAdapterManager, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(MockKyberNetwork, num, 18);
  }).then(() => {
    return deployer.deploy(ExchangeProvider, ExchangeAdapterManager.address, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(KyberNetworkExchange, MockKyberNetwork.address, ExchangeAdapterManager.address, ExchangeProvider.address, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(CentralizedExchange, ExchangeAdapterManager.address, ExchangeProvider.address, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(ExchangeProviderWrap, ExchangeProvider.address);
  })
}

function deployOnMainnet(deployer) {

  let kyberNetwrok = '0xD2D21FdeF0D054D2864ce328cc56D1238d6b239e';
  let permissionProviderAddress = '0x402d3bf5d448871810a3ec8a33fb6cc804f9b26e';
  let coreAddress = '0xd332692cf20cbc3aa39abf2f2a69437f22e5beb9';
  let preDepositETH = 0.1;

  let deploy = deployer.then(() => {
    return deployer.deploy(ExchangeAdapterManager, permissionProviderAddress);
  }).then(() => {
    return deployer.deploy(ExchangeProvider, ExchangeAdapterManager.address, permissionProviderAddress);
  }).then(() => {
    return deployer.deploy(KyberNetworkExchange, kyberNetwrok, ExchangeAdapterManager.address, ExchangeProvider.address, permissionProviderAddress);
  }).then(async () => {

    let kyberExchangeInstance = await KyberNetworkExchange.deployed();
    let exchangeAdapterManager = await ExchangeAdapterManager.deployed();
    let exchangeProvder = await ExchangeProvider.deployed();

    console.info(`adding kyberExchange ${kyberExchangeInstance.address}`);
    let result = await exchangeAdapterManager.addExchange('kyber', kyberExchangeInstance.address);

    console.info(`send ${preDepositETH} ether to kyberExchange`);
    let r = await kyberExchangeInstance.send(web3.toWei(preDepositETH, "ether"));

    console.info('exchange provider set core');
    await exchangeProvder.setCore(coreAddress);
  })
  return deploy;
}

function deployExchangeProviderWrap(deployer, network) {

  let kyberNetwork = KyberConfig[network];
  if (network === 'development') {
    return deployOnDev(deployer, kyberNetwork.mockTokenNum);
  }

  let flags = args.parseArgs();
  var isMockKyber = flags["mockkyber"];
  if (isMockKyber) {
    return deployOnDev(deployer, kyberNetwork.mockTokenNum);
  }

  if (!kyberNetwork) {
    console.error("unkown kyberNetwork address", network)
    return;
  }

  return deployer.then(() => {
    return deployer.deploy(ExchangeAdapterManager, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(ExchangeProvider, ExchangeAdapterManager.address, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(KyberNetworkExchange, kyberNetwork.network, ExchangeAdapterManager.address, ExchangeProvider.address, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(ExchangeProviderWrap, ExchangeProvider.address);
  })
}

module.exports = function (deployer, network) {

  let flags = args.parseArgs();

  if (network == 'mainnet' && flags.contract == "exchange") {
    return deployOnMainnet(deployer, network);
  }else if(network == 'kovan'){
      return deployonkovan(deployer,network);
  }

  return deployer.then(() => {
    return deployer.deploy(PermissionProvider);
  }).then((err, result) => {
    return deployer.deploy(Core, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(StrategyProvider, PermissionProvider.address, Core.address);
  }).then(() => {
    return deployer.deploy(PriceProvider, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(ExtendedStorage, PermissionProvider.address);
  }).then(() => {
    return deployer.deploy(OlympusStorage, PermissionProvider.address);
  }).then(() => {
    return deployExchangeProviderWrap(deployer, network);
  })
}

function deployonkovan(deployer, num) {
    return deployer.then(() => {
        return deployer.deploy(PermissionProvider);
      }).then((err, result) => {
        return deployer.deploy(Core, PermissionProvider.address);
      }).then(() =>{
        return deployer.deploy(StrategyProvider, PermissionProvider.address, Core.address);
      }).then(() => {
        return deployer.deploy(PriceProvider, PermissionProvider.address);
      }).then(() => {
        return deployer.deploy(ExtendedStorage, PermissionProvider.address);
      }).then(() => {
        return deployer.deploy(OlympusStorage, PermissionProvider.address);
      }).then(() => {
        return deployer.deploy(WhitelistProvider, PermissionProvider.address);
      }).then(() => {
        return deployer.deploy(ExchangeAdapterManager, PermissionProvider.address);
      }).then(() => {
        return deployer.deploy(ExchangeProvider, ExchangeAdapterManager.address, PermissionProvider.address);
      }).then(() => {
          kyberNetwrokAddress = '0x65B1FaAD1b4d331Fd0ea2a50D5Be2c20abE42E50';
        return deployer.deploy(KyberNetworkExchange, kyberNetwrokAddress, ExchangeAdapterManager.address, ExchangeProvider.address, PermissionProvider.address);
      }).then( async() => {
        console.info('setPriceProvider');
        let core = await Core.deployed();
        let strategy = await StrategyProvider.deployed();
        let price = await PriceProvider.deployed();
        let extended = await ExtendedStorage.deployed();
        let storage = await OlympusStorage.deployed();
        let whitelist = await WhitelistProvider.deployed();
        let permission = await PermissionProvider.deployed();
        let exchange = await ExchangeProvider.deployed();
        let kyberExchangeInstance = await KyberNetworkExchange.deployed();
        let exchangeAdapterManager = await ExchangeAdapterManager.deployed();
        let exchangeProvder = await ExchangeProvider.deployed();
    
        console.info(`adding kyberExchange ${kyberExchangeInstance.address}`);
        await exchangeAdapterManager.addExchange('kyber', kyberExchangeInstance.address);
    
    
        //需要往这个地址打以太坊作为押金 kyberExchange 
        //console.info(`send ${preDepositETH} ether to kyberExchange`);
        //await kyberExchangeInstance.send(web3.toWei(preDepositETH, "ether"));
    
    
    
        console.info('exchange provider set core');
        await exchangeProvder.setCore(core.address);
    
        console.info('setStrategyProvider');
        await core.setProvider(0, strategy.address);
    
        console.info('setPriceProvider');
        await core.setProvider(1, price.address);
    
        console.info('setExtendedStorageProvider');
        await core.setProvider(2, exchangeProvder.address);
    
        console.info('setExtendedStorageProvider');
        await storage.setProvider(4, extended.address);
    
        console.info('setStorageProvider');
        await core.setProvider(3, storage.address);
    
        console.info('setSWhitelistProvider');
        await core.setProvider(5, whitelist.address);
    
        console.info('SetCore');
        await permission.adminAdd(Core.address,"core");
      }).then(() => {
        //return deployExchangeProviderWrap(deployer, network);
      })
}
