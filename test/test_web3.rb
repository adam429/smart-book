require 'dotenv/load'
require 'smartbook/web3'
require 'pp'
require "minitest/autorun"

class TestWeb3 < Minitest::Test

    def init
        SmartBook::FileCache.skip_cache = []
        SmartBook::FileCache.clear_cache()
        begin
            FileUtils.remove_file(".cache")
        rescue 
        end
    end

    def test_rpc_node_wss
        SmartBook::Web3.init_web3()

        rpc_node = "wss://eth.llamarpc.com"
        SmartBook::Web3.init_provider(rpc_node)

        assert SmartBook::Web3.getBlockNumber().wait_value.class == Integer
        assert SmartBook::Web3.getGasPrice().wait_value.class == Integer

        SmartBook::Web3.destroy_provider
    end

    def test_rpc_node_http
        SmartBook::Web3.init_web3()

        rpc_node = "https://eth-mainnet.public.blastapi.io"
        SmartBook::Web3.init_provider(rpc_node)

        assert SmartBook::Web3.getBlockNumber().wait_value.class == Integer
        assert SmartBook::Web3.getGasPrice().wait_value.class == Integer

        SmartBook::Web3.destroy_provider
    end    

    def test_rpc_node
        init 
        
        SmartBook::Web3.init_web3()

        rpc_node = "wss://eth.llamarpc.com"
        SmartBook::Web3.init_provider(rpc_node)

        block = SmartBook::Web3.getBlock(16000000).wait_value
        # puts JSON.pretty_generate(block)
        assert block["number"] == 16000000

        txhash = block["transactions"][0]
        tx = SmartBook::Web3.getTransaction(txhash).wait_value
        # puts JSON.pretty_generate(tx)
        assert tx["hash"] == txhash


        blocktx = SmartBook::Web3.getBlockWithTransactions(16000000).wait_value
        # puts JSON.pretty_generate(blocktx)
        assert blocktx["number"] == 16000000
        assert blocktx["transactions"][0]["hash"] == txhash


        receipt = SmartBook::Web3.getTransactionReceipt(txhash).wait_value
         # puts JSON.pretty_generate(receipt)
        assert receipt["transactionHash"] == txhash

        code = SmartBook::Web3.getCode("0xdAC17F958D2ee523a2206206994597C13D831ec7").wait_value
        assert code =~ /0x/
        
        store = SmartBook::Web3.getStorageAt("0xdAC17F958D2ee523a2206206994597C13D831ec7",0).wait_value
        assert store =~ /0x/
        assert store.size == 66

        createBlock = SmartBook::Web3.getContractCreationBlock("0xdAC17F958D2ee523a2206206994597C13D831ec7").wait_value
        assert createBlock == 4634748

    end

    def test_etherscan
        init 

        SmartBook::Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])

        tx = SmartBook::Etherscan.getAddressTx("0xdAC17F958D2ee523a2206206994597C13D831ec7").wait_value

        assert tx.size == 10000
        assert tx[0]["blockNumber"] == "4634748"


        assert SmartBook::Etherscan.getBlockNoByTime(Time.now).wait_value > 16400000

        assert SmartBook::Etherscan.getContractCreation("0xdAC17F958D2ee523a2206206994597C13D831ec7").wait_value.first["contractCreator"]  == "0x36928500bc1dcd7af6a2b4008875cc336b927d57"

        assert SmartBook::Etherscan.getTxInternal("0xb571c59c51b2ce35c90ff8152eea7197d78a87d607c7cad977be537310f138a0").wait_value.size  == 2

        abi = SmartBook::Etherscan.getAbi("0xdAC17F958D2ee523a2206206994597C13D831ec7").wait_value
        assert abi.size > 0
        assert abi[0].has_key?("name")
        assert abi[0].has_key?("inputs")
        assert abi[0].has_key?("outputs")
        assert abi[0].has_key?("type")
    end

    def test_contract
        init 
        SmartBook::Web3.init_web3()
        SmartBook::LazyExec.init_jscall()

        rpc_node = "wss://eth.llamarpc.com"
        SmartBook::Web3.init_provider(rpc_node)
        SmartBook::Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])

        SmartBook::Contract.add("usdt",SmartBook::Etherscan.getAbi("0xdAC17F958D2ee523a2206206994597C13D831ec7"),"0xdAC17F958D2ee523a2206206994597C13D831ec7")

        time1 = Time.now
        assert SmartBook::Contract.usdt.name.wait_value == "Tether USD"
        time1 = Time.now-time1

        lazyexec = []
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0xdAC17F958D2ee523a2206206994597C13D831ec7")        
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000000")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000001")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000002")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000003")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000004")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000005")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000006")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000007")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000008")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x0000000000000000000000000000000000000009")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x000000000000000000000000000000000000000A")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x000000000000000000000000000000000000000B")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x000000000000000000000000000000000000000C")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x000000000000000000000000000000000000000D")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x000000000000000000000000000000000000000E")
        lazyexec.push SmartBook::Contract.usdt.balanceOf("0x000000000000000000000000000000000000000F")

        time2 = Time.now
        group = SmartBook::LazyExec.all(lazyexec).wait_value
        time2 = Time.now-time2
        assert group.size == 17

        assert group[0].to_i > 0
        assert time2/time1 < 3

        SmartBook::Web3.destroy_provider

    end
end