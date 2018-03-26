pragma solidity ^0.4.21;

//这个合约控制数据库

library itMaps {

    struct entryBytes32Uint {
        // Equal to the index of the key of this item in keys, plus 1.
        uint keyIndex;
        uint value;
    }

    struct itMapBytes32Uint {
        mapping(bytes32 => entryBytes32Uint) data;
        bytes32[] keys;
    }

    function insert(itMapBytes32Uint storage self, bytes32 key, uint value) internal returns (bool replaced) {
        entryBytes32Uint storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }

    function remove(itMapBytes32Uint storage self, bytes32 key) internal returns (bool success) {
        entryBytes32Uint storage e = self.data[key];
        if (e.keyIndex == 0)
            return false;

        if (e.keyIndex <= self.keys.length) {
            // Move an existing element into the vacated key slot.
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
            self.keys.length -= 1;
            delete self.data[key];
            return true;
        }
    }

    function destroy(itMapBytes32Uint storage self) internal  {
        for (uint i; i<self.keys.length; i++) {
          delete self.data[ self.keys[i]];
        }
        delete self.keys;
        return ;
    }

    function contains(itMapBytes32Uint storage self, bytes32 key) internal constant returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }

    function size(itMapBytes32Uint storage self) internal constant returns (uint) {
        return self.keys.length;
    }

    function get(itMapBytes32Uint storage self, bytes32 key) internal constant returns (uint) {
        return self.data[key].value;
    }

    function getKey(itMapBytes32Uint storage self, uint idx) internal constant returns (bytes32) {
      /* Decrepated, use getKeyByIndex. This kept for backward compatilibity */
        return self.keys[idx];
    }

    function getKeyByIndex(itMapBytes32Uint storage self, uint idx) internal constant returns (bytes32) {
      /* Same as decrepated getKey. getKeyByIndex was introduced to be less ambiguous  */
        return self.keys[idx];
    }

    function getValueByIndex(itMapBytes32Uint storage self, uint idx) internal constant returns (uint) {
        return self.data[self.keys[idx]].value;
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// 正式合约
// 思路是：
// Library存放(
//     sha3(provider_address,TokenAddress,ExchangeHash),price;
//   )

contract PriceOracleInterface {

  function updatePrice(address _tokenAddress,bytes32[] _exchanges,uint[] _prices,uint _nonce) public returns(bool success);

  function getDefaultPrice(address _tokenAddress) public returns(uint);

  function getCustomPrice(address _tokenAddress) public returns(uint);
}

contract PriceOracle is Ownable {
  
  using itMaps for itMaps.itMapBytes32Uint;
  
  address public defaultProvider;
  
  //允许的交易所list 
  mapping(bytes32 => bool) public ExchangeList;
  //允许的Providerlist
  mapping(address => bool) public ProviderList;
  //允许的Tokenlist
  mapping(address => bool) public TokenList;

  mapping(address => uint) public Nonce;
 
  //交易所.Token.Provider 本地记录
  bytes32[] _EXCHANGE;
  address[] _TOKEN;
  address[] _Provider;
  
  //实时价格记录
   //(Provider => (Token => Price))
   mapping(address =>mapping(address=>uint)) Price;
   
  
  
  //日志记录

  event UpdatePrice(address _tokenAddress,bytes32 _exchange,uint price);

  event ExchangeUpdate(bytes32[],bytes32[]);
  
  event TokenUpdate(address[],address[]);
  
  event ProviderUpdate(address[],address[]);
  
  event DefaultProviderUpdate(address,address);
  
  
  //初始化数据库
  itMaps.itMapBytes32Uint priceData;

  function PriceOracle(address _defaultProvider) public {
    defaultProvider = _defaultProvider;
    ProviderList[msg.sender] = true;
    Nonce[_defaultProvider] = 0;
  }

  function updatePrice(address _tokenAddress,bytes32[] _exchanges,uint[] _prices,uint _nonce) public returns(bool success){
      require(ProviderList[msg.sender]);
      require(TokenList[_tokenAddress]);
      require(Nonce[msg.sender] == _nonce);
      require(_exchanges.length == _prices.length&&_prices.length == _EXCHANGE.length);

      for(uint i =0; i < _exchanges.length; i++){
          require(ExchangeList[_exchanges[i]]);
          bytes32 _data = sha3(msg.sender,_tokenAddress,_exchanges[i]);
          priceData.insert( _data, _prices[i]);
          UpdatePrice(_tokenAddress,_exchanges[i],_prices[i]);
      }
      
      Price[msg.sender][_tokenAddress] = NewPriceWeight(msg.sender,_tokenAddress,_exchanges,_prices);
      
      Nonce[msg.sender] = _nonce + 1;
      
      
      return true;
  }
    //TODO
    //getPrice 交给UpdatePrice来执行

    function getDefaultPrice(address _tokenAddress) public returns(uint){
        //定义函数内部变长数组
        uint length = _EXCHANGE.length;
        uint[] memory _priceNow = new uint[](length);

        for (uint i =0; i < _EXCHANGE.length; i ++){
            //priceData.getValueByIndex(k);
            bytes32 _data = sha3(defaultProvider,_tokenAddress,_EXCHANGE[i]);
            _priceNow[i] = (priceData.get(_data));
        }

        uint _price = PriceWeight(_priceNow);

        return _price;

    }

    function getCustomPrice(address _tokenAddress) public returns(uint){
        //定义函数内部变长数组
        uint[] memory _priceNow = new uint[](_EXCHANGE.length);

        for (uint i =0; i < _EXCHANGE.length; i ++){
            
            bytes32 _data = sha3(_tokenAddress,_tokenAddress,_EXCHANGE[i]);
            _priceNow[i] = (priceData.get(_data));
            
        }

        uint _price = PriceWeight(_priceNow);

        return _price;
    }
    
    //新接口
    
    function getNewDefaultPrice(address _tokenAddress) public view returns(uint){
         return Price[defaultProvider][_tokenAddress];
    }
    function getNewCustomPrice(address _Provider,address _tokenAddress) public view returns(uint){
         return Price[_Provider][_tokenAddress];
    }

    function changeExchanges(bytes32[] _newExchanges) public onlyOwner returns(bool success) {
        for (uint i =0; i < _EXCHANGE.length; i ++){
            ExchangeList[_EXCHANGE[i]] = false;
        }
        
        for ( i =0; i < _newExchanges.length; i ++){
            ExchangeList[_newExchanges[i]] = true;
        }
        ExchangeUpdate(_EXCHANGE,_newExchanges);
        _EXCHANGE = _newExchanges;

        //是否清除数据 待测试
        //priceData.destroy();

        return true;
    }  
    //TODO
    function changeTokens(address[] _newTokens) public onlyOwner returns(bool success) {
        
        for (uint i =0; i < _TOKEN.length; i ++){
            TokenList[_TOKEN[i]] = false;
        }
        
        for ( i =0; i < _newTokens.length; i ++){
            TokenList[_newTokens[i]] = true;
        }
        TokenUpdate(_TOKEN,_newTokens);
        _TOKEN = _newTokens;

        //是否清除数据 待测试
        //priceData.destroy();

        return true;
    }
    function changeProviders(address[] _newProviders) public onlyOwner returns(bool success) {
        
        for (uint i =0; i < _Provider.length; i ++){
            ProviderList[_TOKEN[i]] = false;
        }
        
        for ( i =0; i < _newProviders.length; i ++){
            ProviderList[_newProviders[i]] = true;
        }
        ProviderUpdate(_Provider,_newProviders);
        _Provider = _newProviders;

        //是否清除数据 待测试
        //priceData.destroy();

        return true;
    }
    
    //修改默认Provider
    
    function changeDefaultProviders(address _newProvider) public onlyOwner returns(bool success) {
        
        ProviderList[defaultProvider] = false;
        
        ProviderList[_newProvider] = true;
        
        DefaultProviderUpdate(defaultProvider,_newProvider);
        
        defaultProvider = _newProvider;

        //是否清除数据 待测试
        //priceData.destroy();

        return true;
    }
    
    //内部处理权重函数
    function PriceWeight(uint[] _prices) internal returns(uint _price){
        return _prices[0];
    }
    function NewPriceWeight(address _providerAddress,address _tokenAddress,bytes32[] _Exchange,uint[] _prices) internal returns(uint _price){
        return _prices[0];
    }
}



// TODO
// 支持不同Token不同交易所和权重处理
// 支持自定义权重



// TODO
// 支持Nonce 分token处理




