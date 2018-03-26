# PriceOracle

### 测试数据
 ```
tokenAddress: 0x263c618480dbe35c300d8d5ecda19bbb986acaed

exchangeHash: 0x4c2384fe14df4e560ab8e72a65cfb3d873805e9320f7e305e6c0e358c76ff847

Price: 1234

tokenAddress: 0x692a70d2e424a56d2c6c27aa97d1a86395877b3a

exchangeHash: 0x758760f431d5bf0c2e6f8c11dbc38ddba93c5ba4e9b5425f4730333b3ecaf21b

Price: 5678

```

### 测试流程

1. 默认提供价格者地址 

构建初始合约 ```"0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"```

2. 添加数据

添加默认代币   ``` ["0x692a70d2e424a56d2c6c27aa97d1a86395877b3a","0x263c618480dbe35c300d8d5ecda19bbb986acaed"]```

添加默认交易所 ``` ["0x4c2384fe14df4e560ab8e72a65cfb3d873805e9320f7e305e6c0e358c76ff847","0x758760f431d5bf0c2e6f8c11dbc38ddba93c5ba4e9b5425f4730333b3ecaf21b"]```


3. 提交数据

 ``` updatePrice(address _tokenAddress,bytes32[] _exchanges,uint[] _prices,uint _nonce)```



```"0x263c618480dbe35c300d8d5ecda19bbb986acaed",["0x4c2384fe14df4e560ab8e72a65cfb3d873805e9320f7e305e6c0e358c76ff847","0x758760f431d5bf0c2e6f8c11dbc38ddba93c5ba4e9b5425f4730333b3ecaf21b"],[6,7],1```

4.获取数据

```TokenAddress: "0x692a70d2e424a56d2c6c27aa97d1a86395877b3a"```

修改默认Provider

