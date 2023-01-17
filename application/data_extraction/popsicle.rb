require 'smartbook'
require_relative './web3'

ETHERSCAN_API_KEY = "545QYEP8TJKJWMZ7QP41QYXZNMJDVCJUI9"
RPC_NODE = "wss://withered-frosty-yard.discover.quiknode.pro/76b04f5c45862f810107ae9d99a504edbe8a365a/"
# RPC_NODE = "wss://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa"
CONTRACT_PLP_WETHICE = "0xff338d347e59d6b61e5c69382915d863bb22ef2f"

Etherscan.api_key(ETHERSCAN_API_KEY)
Web3.init_provider(RPC_NODE)

Contract.add(:popsicle,JSON.load_file("./abi/PopsicleV3Optimizer.json"),CONTRACT_PLP_WETHICE)

txs = Etherscan.getAddressTx(CONTRACT_PLP_WETHICE)
tx0 = Web3.parseTxs(txs[0]["hash"])
blockNumber = tx0.blockNumber


# time = Time.now
# pool_address, token0, token1 = Jscall.parallelEx(
#   [Contract.popsicle.contract,Contract.popsicle.contract,Contract.popsicle.contract],
#   ["pool","token0","token1"],
#   [nil,nil,nil]
# )
# puts "time: #{Time.now-time}"
# puts "#{pool_address} #{token0} #{token1}"

## Todo:
## all jscall convert to lazy execution
##    Contract.popsicle.pool ==> LazyExec
##        LazyExec.value ==> value
##    LazyExec.batch([a,b,c,d]) ==> [a.value,b.value,c.value,d.value]



Contract.popsicle.send("pool",{:blockTag=>blockNumber})


pool_address, token0, token1 = Thread.wait(
  ->{Contract.popsicle.pool({:blockTag=>blockNumber})},
  ->{Contract.popsicle.token0({:blockTag=>blockNumber})},
  ->{Contract.popsicle.token1({:blockTag=>blockNumber})}
)

Thread.wait(
    ->{Contract.add(:pool,Etherscan.getAbi(pool_address,"./abi/UniswapV3Pool.json"),pool_address)},
    ->{Contract.add(:token0,Etherscan.getAbi(token0,"./abi/ERC20.json"),token0)},
    ->{Contract.add(:token1,Etherscan.getAbi(token1,"./abi/ERC20.json"),token1)}
)

## basic information

Thread.wait(
->{puts "popsicle: #{Contract.popsicle.name({:blockTag=>blockNumber})}" },
->{puts "token0: #{Contract.token0.name({:blockTag=>blockNumber})}" },
->{puts "token1: #{Contract.token1.name({:blockTag=>blockNumber})}" }
)

# # ## get daily data

def next_day(time)
  time-(time.hour * 3600 + time.min*60 +time.sec + time.subsec) + 3600*24
end

blocktime = tx0.blockTime
time = [next_day(blocktime)]

while time.last < Time.now-3600*24
  time << next_day(time.last)
end

time.map.with_index do |t,i|
  block = Etherscan.getBlockNoByTime(t).to_i
  puts "data fetch #{i} at #{t} block #{block}"
  _, tick = Contract.pool.slot0({:blockTag=>block})

  puts "tick: #{tick}"

  tickLower,tickUpper,usersPosition,usersAmounts,poolAmount0,poolAmount1 = Thread.wait(
    ->{Contract.popsicle.tickLower({:blockTag=>block})},
    ->{Contract.popsicle.tickUpper({:blockTag=>block})},
    ->{Contract.popsicle.position({:blockTag=>block})},
    ->{Contract.popsicle.usersAmounts({:blockTag=>block})},
    ->{Contract.token0.balanceOf(Contract.pool.address,{:blockTag=>block})},
    ->{Contract.token1.balanceOf(Contract.pool.address,{:blockTag=>block})}
  )

  ret = {
    index: i,
    time: t,
    block: block,
    tick: tick,
    tickLower: tickLower,
    tickUpper: tickUpper,
    usersPosition: usersPosition[0],
    usersAmounts: usersAmounts,
    poolAmount: [poolAmount0,poolAmount1],
  }
  puts ret.to_s
  ret
end

# # ## get Contract Action

txs = Etherscan.getAddressTx(CONTRACT_PLP_WETHICE)




# # ## get contract tx
Web3.destroy_provider 
