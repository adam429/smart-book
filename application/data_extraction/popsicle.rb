require 'smartbook'
require 'dotenv'

include SmartBook
load_dotenv_recursive

CONTRACT_PLP_WETHICE = "0xff338d347e59d6b61e5c69382915d863bb22ef2f"

FileCache.load_cache
Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])

Web3.init_provider(ENV["RPC_NODE"])


Contract.add(:popsicle,JSON.load_file("./abi/PopsicleV3Optimizer.json"),CONTRACT_PLP_WETHICE)

txs = Etherscan.getAddressTx(CONTRACT_PLP_WETHICE).wait_value
tx0 = SmartBook::Web3.parseTxs(txs[0]["hash"])
blockNumber = tx0.blockNumber

pool_address, token0, token1 = LazyExec.wait_value([Contract.popsicle.pool({blockTag:blockNumber}),
                                                  Contract.popsicle.token0({blockTag:blockNumber}),
                                                  Contract.popsicle.token1({blockTag:blockNumber})])

Thread.wait(
    ->{Contract.add(:pool,Etherscan.getAbi(pool_address,"./abi/UniswapV3Pool.json"),pool_address)},
    ->{Contract.add(:token0,Etherscan.getAbi(token0,"./abi/ERC20.json"),token0)},
    ->{Contract.add(:token1,Etherscan.getAbi(token1,"./abi/ERC20.json"),token1)}
)

# basic information
LazyExec.wait_value([Contract.popsicle.name({blockTag:blockNumber}).then do |v| puts "name: #{v}" end,
                    Contract.token0.name({blockTag:blockNumber}).then do |v| puts "token0: #{v}" end,
                    Contract.token1.name({blockTag:blockNumber}).then do |v| puts "token1: #{v}" end])

# get daily data
def next_day(time)
  time-(time.hour * 3600 + time.min*60 +time.sec + time.subsec) + 3600*24
end

blocktime = tx0.blockTime
time = [next_day(blocktime)]

while time.last < Time.now-3600*24
  time << next_day(time.last)
end

day_data = time.map.with_index do |t,i|
  time = Time.now
  block = Etherscan.getBlockNoByTime(t).to_i
  puts "data fetch #{i} at #{t} block #{block}"

  time = Time.now
  tickLower,tickUpper,usersPosition,usersAmounts,poolAmount0,poolAmount1,slot0 = LazyExec.wait_value(
    [Contract.popsicle.tickLower({:blockTag=>block}),
    Contract.popsicle.tickUpper({:blockTag=>block}),
    Contract.popsicle.position({:blockTag=>block}),
    Contract.popsicle.usersAmounts({:blockTag=>block}),
    Contract.token0.balanceOf(Contract.pool.address,{:blockTag=>block}),
    Contract.token1.balanceOf(Contract.pool.address,{:blockTag=>block}),
    Contract.pool.slot0({:blockTag=>block})]
  )
 
  ret = {
    index: i,
    time: t,
    block: block,
    tick: slot0[1],
    tickLower: tickLower,
    tickUpper: tickUpper,
    usersPosition: usersPosition[0],
    usersAmounts: usersAmounts,
    poolAmount: [poolAmount0,poolAmount1],
  }
  ret
end

# get Contract Action
parsed_txs = txs.map.with_index do |tx,i|
  puts "tx #{i} / #{txs.size}"
  Web3.parseTxs(tx["hash"])
end

parsed_txs = parsed_txs.filter do |tx|  
  ["deposit(uint256,uint256,address)","withdraw(uint256,address)","rebalance()","rerange()"].include?(tx.method_name)
end

parsed_txs.map.with_index do |tx,i|
  block = tx.blockNumber

  puts "parsed_txs #{i} / #{parsed_txs.size}"

  LazyExec.wait_value(
    [Contract.pool.slot0({:blockTag=>block-1}),
    Contract.popsicle.tickLower({:blockTag=>block-1}),
    Contract.popsicle.tickUpper({:blockTag=>block-1}), 
    Contract.popsicle.position({:blockTag=>block-1}),
    Contract.popsicle.usersAmounts({:blockTag=>block}),
    Contract.pool.slot0({:blockTag=>block}),
    Contract.popsicle.tickLower({:blockTag=>block}), 
    Contract.popsicle.tickUpper({:blockTag=>block}),
    Contract.popsicle.position({:blockTag=>block}),
    Contract.popsicle.usersAmounts({:blockTag=>block})]
  )
end

FileCache.save_cache(true)

# destroy 
Web3.destroy_provider 

