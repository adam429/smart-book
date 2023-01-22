require 'smartbook'
require 'parallel'

include SmartBook
load_dotenv_recursive

FileCache.load_cache

at_exit {
  FileCache.save_cache(true)
}


Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])

Web3.init_provider(ENV["RPC_NODE"])

contracts = [
            ["AXS-WETH_0.3","0xa7053782dC3523D2C82B439Acf3f9344Fb47b97f"],
            ["DYDX-WETH_0.3","0xd2C5A739ebfE3E00CFa88A51749d367d7c496CCf"],
            ["FTM-WETH_1","0x949FDF28F437258E7564a35596b1A99b24F81e4e"],
            ["SHIB-WETH_0.3","0xa0273C10b8A4BF0bDC57cb0bC974E3A9d89527b8"],
            ["SHIB-WETH_1","0x495410B129A27bC771ce8fb316d804a5686B8Ea7"],
            ["SPELL-WETH_0.3","0x5C08A6762CAF9ec8a42F249eBC23aAE66097218D"],
            # ["USDC-WETH_0.3","0xaE7b92C8B14E7bdB523408aE0A6fFbf3f589adD9"],
            # ["USDC-WETH_0.05","0x9683D433621A83aA7dd290106e1da85251317F55"],
            ["WBTC-WETH_0.3","0x212Aa024E25A9C9bAF5b5397B558B7ccea81740B"],
            ["WBTC-WETH_0.05","0xBE5d1d15617879B22C7b6a8e1e16aDD6d0bE3c61"],
            ["WETH-ICE_0.3","0xFF338D347E59d6B61E5C69382915D863bb22Ef2f"],
            ["WETH-USDT_0.3","0xa1BE64Bb138f2B6BCC2fBeCb14c3901b63943d0E"],
            ["WETH-USDT_0.05","0x8d8B490fCe6Ca1A31752E7cFAFa954Bf30eB7EE2"],
            # ["MIM-USDC_0.05","0x298b7c5e0770D151e4C5CF6cCA4Dae3A3FFc8E27"],
            # ["USDT-USDC_0.01","0x989442D5cCB27E7931095B0f3165c75a6def9bc3"],
            # ["SDT-UST_0.05","0x92995D179a5528334356cB4Dc5c6cbb1c068696C"],
            # ["USDC-UST_0.05","0xbA38029806AbE4B45D5273098137DDb52dA8e62F"],
            ["WBTC-USDT_0.3","0xd2EF15af2649CC46e3E23B96563a3d44ef5E5A06"],
            ["SAND-WETH_0.3","0xF4f542E4b5E2345A1f2D0fEab9492357Ebc5c8f4"],
            ["ENS-WETH_0.3","0x36e9B6e7FADC7b8Ee289c8A24Ad96573cda3D7D9"]]


def data_fetch(popsicle_contract)
  Contract.add(:popsicle,JSON.load_file("./abi/PopsicleV3Optimizer.json"),popsicle_contract)

  txs = Etherscan.getAddressTx(popsicle_contract).wait_value
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

  day_data = Parallel.map(time,in_threads:10) do |t|
  
  # day_data = time.map do |t|
    time = Time.now
    block = Etherscan.getBlockNoByTime(t).to_i
    puts "data fetch at #{t} block #{block}"
  
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
  
  # # get Contract Action
  # parsed_txs = txs.map.with_index do |tx,i|
  #   puts "tx #{i} / #{txs.size}"
  #   Web3.parseTxs(tx["hash"])
  # end
  
  # parsed_txs = parsed_txs.filter do |tx|  
  #   ["deposit(uint256,uint256,address)","withdraw(uint256,address)","rebalance()","rerange()"].include?(tx.method_name)
  # end
  
  # parsed_txs.map.with_index do |tx,i|
  #   block = tx.blockNumber
  
  #   puts "parsed_txs #{i} / #{parsed_txs.size}"
  
  #   LazyExec.wait_value(
  #     [Contract.pool.slot0({:blockTag=>block-1}),
  #     Contract.popsicle.tickLower({:blockTag=>block-1}),
  #     Contract.popsicle.tickUpper({:blockTag=>block-1}), 
  #     Contract.popsicle.position({:blockTag=>block-1}),
  #     Contract.popsicle.usersAmounts({:blockTag=>block-1}),
  #     Contract.pool.slot0({:blockTag=>block}),
  #     Contract.popsicle.tickLower({:blockTag=>block}), 
  #     Contract.popsicle.tickUpper({:blockTag=>block}),
  #     Contract.popsicle.position({:blockTag=>block}),
  #     Contract.popsicle.usersAmounts({:blockTag=>block})]
  #   )
  # end
  

end

contracts.each do |name,address|
  puts "== fetch #{name} =="
  data_fetch(address)
end


# destroy 
Web3.destroy_provider 
