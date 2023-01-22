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

        rpc_node = "wss://eth-mainnet.public.blastapi.io"
        SmartBook::Web3.init_provider(rpc_node)

        assert SmartBook::Web3.getBlockNumber().wait_value.class == Integer
        assert SmartBook::Web3.getGasPrice().wait_value.class == Integer

        SmartBook::Web3.destroy_provider
    end

    def test_rpc_node_http

        rpc_node = "https://eth-mainnet.public.blastapi.io"
        SmartBook::Web3.init_provider(rpc_node)

        assert SmartBook::Web3.getBlockNumber().wait_value.class == Integer
        assert SmartBook::Web3.getGasPrice().wait_value.class == Integer

        SmartBook::Web3.destroy_provider
    end    

    def test_rpc_node
        init 
        

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


        assert SmartBook::Etherscan.getBlockNoByTime(Time.now).wait_value.to_i > 16400000

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

    def test_transaction
        init 

        rpc_node = "wss://eth.llamarpc.com"
        SmartBook::Web3.init_provider(rpc_node)
        SmartBook::Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])

        tx = SmartBook::Etherscan.getAddressTx("0xdAC17F958D2ee523a2206206994597C13D831ec7").wait_value

        parse = SmartBook::Web3.parseTxs(tx[0]["hash"])

        assert parse.type == "contract_creation"
        assert parse.method_name == "[contract_creation]"
        assert parse.status == "success"
        assert parse.to == nil

        parse = SmartBook::Web3.parseTxs(tx[1]["hash"])

        assert parse.type == "method_call"
        assert parse.method_name == "transferOwnership(address)"
        assert parse.status == "failure"
        assert parse.to == "0xdAC17F958D2ee523a2206206994597C13D831ec7"

        SmartBook::Web3.destroy_provider
    end

    def test_lazyexec
        init

        rpc_node = "wss://eth.llamarpc.com"
        SmartBook::Web3.init_provider(rpc_node)
        SmartBook::Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])
        hash = "0x2f1c5c2b44f771e942a8506148e256f94f1a464babc938ae0690c6e34cd79190"


        10.times do
            init

            tx_internal, tx, receipt = SmartBook::LazyExec.wait_value(
                [SmartBook::Etherscan.getTxInternal(hash),
                SmartBook::Web3.getTransaction(hash),
                SmartBook::Web3.getTransactionReceipt(hash)])

            init

            assert tx_internal.to_a.size == SmartBook::Etherscan.getTxInternal(hash).wait_value.to_a.size
            assert tx.to_a.size == SmartBook::Web3.getTransaction(hash).wait_value.to_a.size
            assert receipt.to_a.size == SmartBook::Web3.getTransactionReceipt(hash).wait_value.to_a.size
        end
    end

    def test_digest
        init 

        assert SmartBook::Contract.search_digest("0x00f714ce")[0] == "withdraw(uint256,address)"
        assert SmartBook::Contract.search_digest("0x2fb985eb745b9e89bb1ab82e0f8ceb6bf94d4d60aed7e8196540c50161a5fe91")[0] == "CompoundFees(uint256,uint256)"

        assert SmartBook::Contract.search_digest("0x0000")[0] == "digest not found"
        assert SmartBook::Contract.search_digest("0x000000ff")[0] == "digest not found"
        assert SmartBook::Contract.search_digest("0x0000000000000000000000000000000000000000000000000000000000000000")[0] == "digest not found"
    end

    def test_cache
        init 

        SmartBook::Etherscan.api_key(ENV["ETHERSCAN_API_KEY"])

        rpc_node = "wss://eth-mainnet.public.blastapi.io"
        SmartBook::Web3.init_provider(rpc_node)

        hash = "0xac8f412e95395a2417b0ccfb0453b73a261c9f087edaafbdc42426659ad9088a"

        time1 = Time.now
        SmartBook::Web3.parseTxs(hash)
        time1 = Time.now-time1

        time2 = Time.now
        SmartBook::Web3.parseTxs(hash)
        time2 = Time.now-time2

        assert time1 > time2*10

        SmartBook::Web3.destroy_provider

    end
end