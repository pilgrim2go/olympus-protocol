pragma solidity ^0.4.21;

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

contract PriceInterface{
    function getPrice( ) external returns (uint _prices);
    function updatePrices(address tokenAddress, bytes32 _Exchanges,  uint _prices) external returns (bool success);
} 

contract PriceProvider is  Ownable {

    uint public nonce;
    mapping(address => address ) token;

    event PriceUpdated(uint _nonce, address tokenAddress, bytes32 _exchanges,uint _price);
    event AddNewToken(address _tokencontractaddress,address _tokenaddress);
    event ChangeToken(address _tokencontractaddress,address _tokennewaddress);
    
    event GetLatestPrice(address tokenAddress,uint _latestprice);
    event GetResult(bytes32[] _exchanges, uint[] _price);

    function PriceProvider (uint _number) public {
        nonce = _number;
    }       
    
    function addNewToken(address tokencontractaddress,address tokenaddress) public onlyOwner {
        
        require(tokenaddress != address(0));
        require(tokencontractaddress != address(0));
        
        token[tokencontractaddress] = tokenaddress;
        
        AddNewToken(tokencontractaddress,tokenaddress);
    }
    
    function changeToken(address tokencontractaddress, address newTokenAddress) public onlyOwner {
        //require(newTokenAddress != address(0));
        
        require(tokencontractaddress != address(0));
        require(token[tokencontractaddress] != address(0));
        
        token[tokencontractaddress] = newTokenAddress;
        
        ChangeToken(tokencontractaddress,newTokenAddress);
    }
    
    //Data
    function updatePrices(address tokenAddresses, bytes32[] _Exchanges,  uint[] _prices, uint _nonce) external returns (bool success){
        require(nonce == _nonce);
        
        require(_Exchanges.length == _prices.length);
        
        require(token[tokenAddresses] != address(0));

        nonce = _nonce + 1;
        
        PriceInterface price = PriceInterface(token[tokenAddresses]);
        
        for(uint i=0; i<_Exchanges.length;i++){
            price.updatePrices(tokenAddresses,_Exchanges[i],_prices[i]);
        }
        return true;
    }

    function getPrice(address tokenAddresses) external returns (uint _prices){
        require(token[tokenAddresses] != address(0));
        
        PriceInterface _price = PriceInterface(token[tokenAddresses]);
        
        return _price.getPrice();
        
    }
    

    function getNonce() public constant returns(uint) {
        return nonce;
    }  
}


