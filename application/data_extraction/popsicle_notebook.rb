require 'smartbook'
require_relative './web3'

RPC_NODE = "https://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa"
ETHERSCAN_API_KEY = "545QYEP8TJKJWMZ7QP41QYXZNMJDVCJUI9"


CONTRACT_PLP_WETHICE = "0xff338d347e59d6b61e5c69382915d863bb22ef2f"

Etherscan.api_key(ETHERSCAN_API_KEY)
Web3.init_provider(RPC_NODE)



Contract.add(:popsicle,JSON.load_file("./abi/PopsicleV3Optimizer.json"),CONTRACT_PLP_WETHICE)


# all the txs
txs = Etherscan.getAddressTx(CONTRACT_PLP_WETHICE)

#--------------------------------


p Web3.parseTxs(txs[0]["hash"])  ## contract_creation

pool_address = Contract.popsicle.pool({:blockTag=>13550675})  
strategy_address = Contract.popsicle.strategy({:blockTag=>13550675})  
token0 = Contract.popsicle.token0({:blockTag=>13550675});
token1 = Contract.popsicle.token1({:blockTag=>13550675});
tickSpacing = Contract.popsicle.tickSpacing({:blockTag=>13550675});
governance = Contract.popsicle.governance({:blockTag=>13550675});


Contract.add(:pool,Etherscan.getAbi(pool_address,"./abi/UniswapV3Pool.json"),pool_address)
Contract.add(:token0,Etherscan.getAbi(token0,"./abi/ERC20.json"),token0)
Contract.add(:token1,Etherscan.getAbi(token1,"./abi/ERC20.json"),token1)

p "token0: #{Contract.token0.symbol({:blockTag=>13550675})}"
p "token1: #{Contract.token1.symbol({:blockTag=>13550675})}"


#--------------------------------
p Web3.parseTxs(txs[1]["hash"]) # approveOperator

p Contract.popsicle.isOperator("0x3c1cb7d4c0ce0dc72edc7ea06acc866e62a8f1d8", {:blockTag=>13550691}) # => false
p Contract.popsicle.isOperator("0x3c1cb7d4c0ce0dc72edc7ea06acc866e62a8f1d8", {:blockTag=>13550692}) # => true


#--------------------------------

p Web3.parseTxs(txs[2]["hash"]) # init
p Contract.popsicle.initialized({:blockTag=>13550692-1}) # => false
p Contract.popsicle.initialized({:blockTag=>13550692}) # => false

p Contract.pool.slot0({:blockTag=>13550692})[1] 
p Contract.popsicle.tickLower({:blockTag=>13550692}) 
p Contract.popsicle.tickUpper({:blockTag=>13550692}) 

#--------------------------------

p Web3.parseTxs(txs[3]["hash"])  # withdraw

p Contract.popsicle.balanceOf("0x3c1cb7d4c0ce0dc72edc7ea06acc866e62a8f1d8",{:blockTag=>13550734-1}) - Contract.popsicle.balanceOf("0x3c1cb7d4c0ce0dc72edc7ea06acc866e62a8f1d8",{:blockTag=>13550734})

# withdraw 10000000000000 eth

p Contract.popsicle.totalSupply({:blockTag=>13550734-1})

p Contract.popsicle.position({:blockTag=>13550734-1})
p Contract.popsicle.usersAmounts({:blockTag=>13550734-1})

p Contract.popsicle.position({:blockTag=>13550734})
p Contract.popsicle.usersAmounts({:blockTag=>13550734})

#--------------------------------

p Web3.parseTxs(txs[4]["hash"])

#--------------------------------
p Web3.parseTxs(txs[5]["hash"])
p Web3.parseTxs(txs[5]["hash"]).method_name
p Web3.parseTxs(txs[5]["hash"]).tx["blockNumber"]

puts "==before=="
p Contract.pool.slot0({:blockTag=>13552751})[1] 
p Contract.popsicle.tickLower({:blockTag=>13552751}) 
p Contract.popsicle.tickUpper({:blockTag=>13552751}) 
p Contract.popsicle.position({:blockTag=>13552751})
p Contract.popsicle.usersAmounts({:blockTag=>13552751})


puts "==after=="
p Contract.pool.slot0({:blockTag=>13552752})[1] 
p Contract.popsicle.tickLower({:blockTag=>13552752}) 
p Contract.popsicle.tickUpper({:blockTag=>13552752}) 
p Contract.popsicle.position({:blockTag=>13552752})
p Contract.popsicle.usersAmounts({:blockTag=>13552752})

#--------------------------------
p Web3.parseTxs(txs[6]["hash"]).method_name
p Web3.parseTxs(txs[6]["hash"]).tx["blockNumber"]


puts "==before=="
p Contract.pool.slot0({:blockTag=>13555052})[1] 
p Contract.popsicle.tickLower({:blockTag=>13555052}) 
p Contract.popsicle.tickUpper({:blockTag=>13555052}) 
p Contract.popsicle.position({:blockTag=>13555052})
p Contract.popsicle.usersAmounts({:blockTag=>13555052})


puts "==after=="
p Contract.pool.slot0({:blockTag=>13555053})[1] 
p Contract.popsicle.tickLower({:blockTag=>13555053}) 
p Contract.popsicle.tickUpper({:blockTag=>13555053}) 
p Contract.popsicle.position({:blockTag=>13555053})
p Contract.popsicle.usersAmounts({:blockTag=>13555053})


p txs.map {|x| Web3.parseTxs(x["hash"]) }.map.with_index {|x|  x.method_name }

p txs.map {|x| Web3.parseTxs(x["hash"]) }.map.with_index {|x|  x.method_name }.uniq



p txs.map {|x| Web3.parseTxs(x["hash"]) }.filter {|x|  x.method_name == "approve(address,uint256)" }
p txs.map {|x| Web3.parseTxs(x["hash"]) }.filter {|x|  x.method_name == "transfer(address,uint256)" }


p txs.map {|x| Web3.parseTxs(x["hash"]) }.filter {|x|  x.method_name == "deposit(uint256,uint256,address)" }.first

p txs.map {|x| Web3.parseTxs(x["hash"]) }.filter {|x|  x.method_name == "rerange()" }.first



puts "==before=="
p Contract.pool.slot0({:blockTag=>13576959})[1] 
p Contract.popsicle.tickLower({:blockTag=>13576959}) 
p Contract.popsicle.tickUpper({:blockTag=>13576959}) 
p Contract.popsicle.position({:blockTag=>13576959})
p Contract.popsicle.usersAmounts({:blockTag=>13576959})


puts "==after=="
p Contract.pool.slot0({:blockTag=>13576960})[1] 
p Contract.popsicle.tickLower({:blockTag=>13576960}) 
p Contract.popsicle.tickUpper({:blockTag=>13576960}) 
p Contract.popsicle.position({:blockTag=>13576960})
p Contract.popsicle.usersAmounts({:blockTag=>13576960})



puts FileCache.cache_size

# event
#    deposit / withdraw / rebalance / rerange
# metrics
#  - price change over time (per day / per action)
#  - liquidity change over time (per day / per action)
#  - value (in Token1) change over time (per day / per action)
#  - upper/lower tick change over time (rerange / rebalance) (per day / per action)
