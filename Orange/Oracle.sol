pragma solidity ^0.4.21;

//这个合约控制单币种价格序列

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

contract PriceWeightInterface{
    function getPrice(address tokenaddress, bytes32[] _Exchanges,  uint[] _prices) public returns(uint price);
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

contract TokenPrice is Ownable {
        
        uint size;
        
        using itMaps for itMaps.itMapBytes32Uint;
        
        address public _tokenaddress;
        itMaps.itMapBytes32Uint priceData;
        address public periceWeightAddress;
        
        event GetLatestPrice(address tokenAddress,uint _latestprice);
        event GetResult(bytes32[] _exchanges, uint[] _price);
        event PriceUpdated(address, bytes32, uint);

        function TokenPrice(address _Tokenaddress) {
            _tokenaddress = _Tokenaddress;
            //periceWeightAddress = weightAddress;
        }
        
        //msg.sender检测放到前置合约
        //这里明确接受币的地址
        
        
        
    
    function updatePrice(address tokenAddress, bytes32 _Exchange,  uint _price) external returns (bool success){
        //require(_Exchanges.length == _prices.length);
        require(_tokenaddress == tokenAddress);
        
        //for (var index = 0; index < _Exchanges.length; index++) {
        //    IterableMapping.insert(priceData, _Exchanges[index], _prices[index]);
        //    PriceUpdated(tokenAddress, _Exchanges[index], _prices[index]);
        //    Size(priceData.size);
        //}
        priceData.insert( _Exchange, _price);
        
        size = priceData.size();
        
        return true;
    }
    
    function getPrice() external returns (uint _prices){
        
        bytes32[]  memory _a = new bytes32[](size);
        uint[] memory  _b = new uint[](size);
        
        for(uint k =0;k<priceData.size();k++){
            _a[k] = priceData.getKeyByIndex(k);
            _b[k] = priceData.getValueByIndex(k);
        }
        return _b[0];
    }
    
    function weight(bytes32[] _Exchanges,uint[] _Prices) internal returns(uint) {
        return _Prices[1];
    }
    
}
