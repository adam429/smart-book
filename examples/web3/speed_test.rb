require 'smartbook'

RPC_NODE = [
    # ["cloudflare","https://cloudflare-eth.com"], # 13

    # ["llama","https://eth.llamarpc.com"], #24
    # ["llama-wss","wss://eth.llamarpc.com"], #15

    # ["linkpool","https://main-light.eth.linkpool.io/"],  #error
    # ["linkpool-wss","wss://main-light.eth.linkpool.io/ws"], #error

    # ["blockpi","https://ethereum.blockpi.network/v1/rpc/0d003da4ffe05dddac1b42406674f5c94963df7d"], #11
    ["blockpi-wss","wss://ethereum.blockpi.network/v1/ws/0d003da4ffe05dddac1b42406674f5c94963df7d"], #8
    # ["blockpi-public","https://ethereum.blockpi.network/v1/rpc/public"], #11

    # ["getblock","https://eth.getblock.io/api_key/mainnet/"], # error
    # ["getblock-wss","wss://eth.getblock.io/api_key/mainnet/"], # error


    # ["alchemy","https://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa"], #24
    # ["alchemy","wss://eth-mainnet.g.alchemy.com/v2/xOu9KmQYmgmqBuYhhPW0naOB9YRY3foa"], #16
    # ["alchemy-public","https://eth-mainnet.g.alchemy.com/v2/demo"],	#27

    # ["quicknode","https://withered-frosty-yard.discover.quiknode.pro/76b04f5c45862f810107ae9d99a504edbe8a365a/"], #25
    # ["quicknode-wss","wss://withered-frosty-yard.discover.quiknode.pro/76b04f5c45862f810107ae9d99a504edbe8a365a/"], #34
    

    # ["sg.blxrbdn","https://singapore.rpc.blxrbdn.com"], #9
    # ["uk.blxrbdn","https://uk.rpc.blxrbdn.com"], #28
    # ["us.blxrbdn","https://virginia.rpc.blxrbdn.com"],	#32

    
    # ["pokt.network","https://eth-mainnet.gateway.pokt.network/v1/lb/a3f2f1189b88a981fa979e36"], #11
    # ["pokt.network-public","https://eth-rpc.gateway.pokt.network"],	 #10

    # ["chainstack","https://nd-765-160-782.p2pify.com/1cfb485d97ab6f463c740518639b6cf2"], # 10
    # ["chainstack-wss","wss://ws-nd-765-160-782.p2pify.com/1cfb485d97ab6f463c740518639b6cf2"], #12

    # ["blastapi","https://eth-mainnet.public.blastapi.io"],	#9
    
    ["blastapi-wss","wss://eth-mainnet.blastapi.io/0a1d7766-b53d-4fdd-a8a1-5627f675930a"],  #2 
    ["blastapi-wss-public","wss://eth-mainnet.public.blastapi.io"],  #1  

    # ["infura","https://mainnet.infura.io/v3/48efede478bd4fbf962ae3eefa30788e"], #31

    # ["ankr-public","https://rpc.ankr.com/eth"],	 #10
    # ["ankr","https://rpc.ankr.com/eth/a182aaedbff009506d020e5cd898c153e99270b5da7fc3ed973bc7e8ee037dd8"], # error
    # ["ankr-wss","wss://rpc.ankr.com/eth/ws/a182aaedbff009506d020e5cd898c153e99270b5da7fc3ed973bc7e8ee037dd8"], # error

    # ["nodereal","https://eth-mainnet.nodereal.io/v1/1659dfb40aa24bbb8153a677b98064d7"],	 #14
    # ["bitstack","https://api.bitstack.com/v1/wNFxbiJyQsSeLrX8RRCHi7NpRxrlErZk/DjShIqLishPCTB9HiMkPHXjUM9CNM9Na/ETH/mainnet"],	 #11
    # ["builder0x69","https://rpc.builder0x69.io"], #79
    # ["payload","https://rpc.payload.de"], #24	
    # ["publicnode"," https://ethereum.publicnode.com"],	 #error
    # ["securerpc","https://api.securerpc.com/v1"],	#47
    # ["omniatech","https://endpoints.omniatech.io/v1/eth/mainnet/public"], #31
    # ["zmok","https://api.zmok.io/mainnet/oaen6dy8ff6hju9k"], #34
    # ["flashbots","https://rpc.flashbots.net"],	#47

    # ["unifra","https://eth-mainnet-public.unifra.io"], #49
    # ["1rpc","https://1rpc.io/eth"] #27
]

SmartBook::FileCache.stop_cache

RPC_NODE.each do |name,rpc|
    begin
        SmartBook::Web3.init_provider(rpc)

        time = Time.now

        block = SmartBook::Web3.getBlockNumber().wait_value

        SmartBook::LazyExec.wait_value((block-100..block).to_a.map do |x|
            SmartBook::Web3.getBlockWithTransactions(x)
        end)
        SmartBook::Web3.destroy_provider 
 
        puts "rpc: #{name} | time: #{Time.now-time}s"
    rescue => e
        puts "rpc: #{name} | error: #{e}"
        Jscall.close

        SmartBook::Web3.init_jscall()
        SmartBook::LazyExec.init_jscall()
    end

end

