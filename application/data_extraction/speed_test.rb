require 'smartbook'
require_relative './web3'

RPC_NODE = [

# "https://nd-431-941-913.p2pify.com/033947f49cd6564ef6011cfcac70e958",  # 6s
"wss://ws-nd-431-941-913.p2pify.com/033947f49cd6564ef6011cfcac70e958",  # 2s
# "https://beacon-nd-431-941-913.p2pify.com/033947f49cd6564ef6011cfcac70e958",

# "https://attentive-falling-haze.discover.quiknode.pro/582d2ad8f6c2a1595863481ae3608340ae29312c/",  # 40s
# "wss://attentive-falling-haze.discover.quiknode.pro/582d2ad8f6c2a1595863481ae3608340ae29312c/", # 25s

# "https://rpc.ankr.com/eth/a182aaedbff009506d020e5cd898c153e99270b5da7fc3ed973bc7e8ee037dd8",  # 4.5s
# -- "wss://rpc.ankr.com/eth/ws/a182aaedbff009506d020e5cd898c153e99270b5da7fc3ed973bc7e8ee037dd8",

# "https://mainnet.infura.io/v3/48efede478bd4fbf962ae3eefa30788e",  #47s

# "https://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa",  #15s
# "wss://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa", #10s

]

FileCache.stop_cache

RPC_NODE.each do |rpc|
    puts "rpc: #{rpc} | start"

    Web3.init_provider(rpc)

    time = Time.now

    block = Web3.getBlockNumber()

    # puts Jscall.parallel(nil,"getBlockWithTransactions",(block-100..block).to_a,12).inspect

    puts "rpc: #{rpc} | time: #{Time.now-time}s"
end
Web3.destroy_provider 
