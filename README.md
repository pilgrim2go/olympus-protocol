
# Protocol Architecture

## Index Main Architecture

```
<User>            [Core Smart Contract]           [Price Oracle]              [Exchange Privider]       <Exchange>
  |------- send eth ------->|
                            |------- request price ----->|
                                                         |------------------- request price --------------->|
                                                         |<------------------ response price ---------------|
                            |<------ response price -----|
                            |------- split orders ------- && ------ make orders ------->|
                                                                                        |---- exchange ---->|
                                                                                        |<--- done ---------|
  |<----------------------- orders completion && return ask tokens ---------------------|
  ```

### Exchange Privider

```node
contract ExchangeProvider {

  struct ProviderStatus {
    bool isRunning,
    string name,
    uint fee
  }

  enum TradeStatusCode {
    OK,
    Expired,
    Pending,
    NotFound,
    Failure
  }

  struct TradeStatus {
    string tradeId,
    string pair,
    uint totalAmount,
    uint completedAmout,
    TradeStatusCode code
  }

  event TradeComplete(TradeStatus);

  enum OrderType {
    Default,  // default as Market
    Limit,
    Market
  }

  function ExchangeProvider() public {}

  function getProviderStatus() public return (ProviderStatus) { ... }

  function getExpectedRate(string _from, string _to) public return (uint) { ... }

  function excuteTrade(string _from, uint _amount, string _to, OrderType _type) public payable return (string) { ... }

  function getTradeStatus(string _tradeId) public return (TradeStatus) { ... }

  function updateTradeStatus(TradeStatus) public { ... }

}
```

### Price Oracle
### Core
