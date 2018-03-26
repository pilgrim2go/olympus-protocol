contract PriceOracleInterface {
    function updatePrice(address _tokenAddress,bytes32[] _exchanges,uint[] _prices,uint _nonce) public returns(bool success);
    //花费GAS
    function getDefaultPrice(address _tokenAddress) public returns(uint);
    function getCustomPrice(address _tokenAddress) public returns(uint)；
    
    //不花费GAS
    function getNewDefaultPrice(address _tokenAddress) public view returns(uint);
    function getNewCustomPrice(address _Provider,address _tokenAddress) public view returns(uint);
}
