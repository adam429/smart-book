require 'objspace'
require 'json'  
require 'uri'
require 'net/http'
require 'jscall'
require 'keccak256'
require 'pp'
require 'thread'

class Thread
    def self.wait(*args)
        args.map {|x| Thread.new(&x) }.map {|x| x.join }.map {|x| x.value}
    end
end

class FileCache
    @@cache = {}
    @@semaphore = Mutex.new
    @@enable = true

    def self.cache
        @@cache
    end
    def self.stop_cache
        @@enable = false
    end

    def self.start_cache
        @@enable = true
    end

    def self.cache=(cache)
        @@cache=cache
    end

    def self.save_cache
        File.open(".cache","w") do |file|
            file.write(JSON.pretty_generate(@@cache))
        end
    end

    def self.restore_cache
        begin
            @@cache = JSON.load(File.open(".cache","r").read())
        rescue
        end
    end

    def self.cache_size
        JSON.generate(@@cache).size
    end

    def self.force_update_cache(key,&block)
        return block.call if @@enable == false

        ret = block.call

        return ret if ret.class== Jscall::RemoteRef

        @@cache[key] = ret
        self.save_cache

        return ret
    end

    def self.update_cache(key,&block)
        return block.call if @@enable == false

        return block.call if key.gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",").include?("latest")
        return @@cache[key] if @@cache.has_key?(key)

        ret = block.call
        return ret if ret.class== Jscall::RemoteRef

        @@cache[key] = ret
        self.save_cache

        return ret
    end

    def self.delete_cache(key)
        @@cache.delete(key)
        self.save_cache
    end


    ## ==todo==
    ## decouple logic to pure FileCahce,
    ## create abstract class Cache --> FileCache / RedisCache
    ## Web3 cache with abstract class Cache
    ## todo add cache write / read count and time

    def self.read_cache(key)
        return @@cache[key]
    end

    def self.write_cache(key,value)
        @@cache[key] = value
        self.save_cache
    end

    def self.skip_cache(value)
    end
end


FileCache.restore_cache

# class Web3 < FileCache
#     def self.update_cache(key,&block)
#         return block.call if key.gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",").include?("latest")
#         return @@cache[key] if @@cache[key]

#         ret = block.call
#         @@cache[key] = ret
#         self.save_cache

#         return ret
#     end

#     def self.delete_cache(key)
#         @@cache.delete(key)
#         self.save_cache
#     end
# end


class Contract < FileCache
    @@list = {}
    @@abi_mapping = FileCache.cache["abi_mapping"] || {}

    def self.list
        @@list
    end

    def self.abi_mapping
        @@abi_mapping
    end

    def self.add(name,abi,address)        
        contract = Web3.contract(abi,address)
        @@list[name.to_sym] = 
            {
                :contract => contract,
                :ruby_obj => self.new(contract,name,address),
                :abi => abi,
            }
        self._generate_abi_mapping(abi)
    end
    
    def self._generate_abi_mapping(abi)
        
        abi.filter {|x| x["type"]=="function" }.each do |x|
            str = "#{x["name"]}(#{x["inputs"].map {|i| i["type"]}.join(",")})"
            name = x["inputs"].map {|i| i["name"]}.join(",")
            digest = "0x"+Digest::Keccak256.new.hexdigest(str)[0..7]
            @@abi_mapping[digest] = [str,name]
        end
        abi.filter {|x| x["type"]=="event" }.each do |x|
            str = "#{x["name"]}(#{x["inputs"].map {|i| i["type"]}.join(",")})"
            name = x["inputs"].map {|i| "#{i["name"]}#{i["indexed"] ? ":indexed" : ""}" }.join(",")
            digest = "0x"+Digest::Keccak256.new.hexdigest(str)
            @@abi_mapping[digest] = [str,name]
        end

        force_update_cache(:abi_mapping) do
            @@abi_mapping
        end
    end

    def self.search_digest(digest)
        return @@abi_mapping[digest] if @@abi_mapping[digest]

        raise "todo search in 4byte.directory api #{digest}"
        ## todo search in 4byte.directory api
    end

    def self.method_missing(name, *args)
        if @@list[name.to_sym] then
            return @@list[name.to_sym][:ruby_obj]
        else
            super
        end
    end

    def initialize(contract,name,address)
        @contract = contract
        @name = name
        @address = address
    end

    def self.convertBigNumberToString(obj)
        ret = obj

        if obj.class == Jscall::RemoteRef and obj.send("_isBigNumber") then
            ret = obj.send("toString").to_i
        end

        if obj.class == Array then
            ret = obj.map {|x| self.convertBigNumberToString(x) }
        end

        return ret
    end

    def method_missing(name, *args)
        if args.last.class == Hash and args.last[:blockTag].to_i>0 then

            self.class.update_cache("#{@address}.#{@name}.#{name}(#{args.join(",")})") do    
                @@semaphore.synchronize do                
                    ret = @contract.send(name,*args)
                    ret = self.class.convertBigNumberToString(ret)
                    ret
                end
            end
        else
            @contract.send(name,*args)
                @@semaphore.synchronize do                
                    ret = @contract.send(name,*args)
                    ret = self.class.convertBigNumberToString(ret)
                    ret
                end
        end
    end
end


class Etherscan < FileCache
    def self.api_key(key)
        @@etherscan_api_key = key
    end

    def self.getAddressTx(address)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            url = "https://api.etherscan.io/api?module=account&action=txlist&address=#{address}&startblock=0&endblock=99999999&page=0&offset=0&sort=asc&apikey=#{@@etherscan_api_key}"

            ret = JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
        end
    end

    def self.getTxInternal(txhash)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            url = "https://api.etherscan.io/api?module=account&action=txlistinternal&txhash=#{txhash}&apikey=#{@@etherscan_api_key}"

            ret = JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
        end
    end

    def self.getAbi(address,fallback_file=nil)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            url = "https://api.etherscan.io/api?module=contract&action=getabi&address=#{address}&apikey=#{@@etherscan_api_key}"

            ret = JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]

            if ret =="Contract source code not verified" then
                ret = JSON.load_file(fallback_file) if fallback_file 
            else
                ret = JSON.load(ret)
            end


            ret 
        end
    end        


    def self.getContractCreation(address)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            url = "https://api.etherscan.io/api?module=contract&action=getcontractcreation&contractaddresses=#{address}&apikey=#{@@etherscan_api_key}"

            ret = JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
        end
    end        
    
    def self.getBlockNoByTime(timestamp)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            url = "https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp=#{timestamp.to_i}&closest=before&apikey=#{@@etherscan_api_key}"

            ret = JSON.load(Net::HTTP.get_response(URI(url)).body)["result"].to_i
        end
    end        

end

class Web3 < FileCache
    Jscall.exec <<CODE
        const { PromisePool } = require('@supercharge/promise-pool')

        global.ethers = require('ethers')
    
        async function parallel(obj,func, argv, concurrency=10)
        {
            return (await PromisePool.for(argv).withConcurrency(concurrency).process(async item => {
                if (obj==null) { obj = global }
                return await obj[func](item)
              })).results
        }
    
        async function parallelEx(obj,func, argv, concurrency=10)
        {
            return (await PromisePool.for([...Array(obj.length).keys()]).withConcurrency(concurrency).process(async index => {
                if (obj[index]==null) { obj[index] = global }
                return await obj[index][func[[index]]](argv[index])
              })).results
        }
    
        async function init_provider(rpc_node) {
            global.provider = await new ethers.getDefaultProvider(rpc_node)        
        }

        async function destroy_provider(){
            await global.provider.destroy()            
        }

        async function init_contract(abi,address)
        {
            return await new ethers.Contract(address, abi, global.provider)
        }

        async function getTransaction(txhash)
        {
            let tx = await global.provider.getTransaction(txhash);
            
            delete tx.wait
            delete tx.accessList

            const map = new Map();

            for (let key in tx) {
                if (tx[key]!=null && tx[key]._isBigNumber) {
                    tx[key] = tx[key].toString()
                }
                map.set(key,tx[key])
            }

            return map
        }

        async function getBlockWithTransactions(blockno)
        {
            let block = await global.provider.getBlockWithTransactions(blockno);

            const map = new Map();

            for (let key in block) {
                if (block[key]!=null && block[key]._isBigNumber) {
                    block[key] = block[key].toString()
                }
                if (key!="transactions") {
                    map.set(key,block[key])
                }
            }

            const transactions = []

            for (let  key in block.transactions) {
                let  item = new Map();
                data = block.transactions[key]
                delete data.wait
                delete data.accessList

                for (let  key2 in data) {
                    if (data[key2]!=null && data[key2]._isBigNumber) {
                        data[key2] = data[key2].toString()
                    }
                    item.set(key2,data[key2])
                }
                transactions.push(item)
            }

            map.set("transactions",transactions)


            return map
        }

        async function getBlock(blockno)
        {
            let block = await global.provider.getBlock(blockno);

            const map = new Map();

            for (let key in block) {
                if (block[key]!=null && block[key]._isBigNumber) {
                    block[key] = block[key].toString()
                    
                }
                map.set(key,block[key])
            }

            return map
        }


        async function getTransactionReceipt(txhash)
        {
            let receipt = await global.provider.getTransactionReceipt(txhash);
            
            const map = new Map();

            for (let key in receipt) {
                if (receipt[key]!=null && receipt[key]._isBigNumber) {
                  receipt[key] = receipt[key].toString()
                }
                if (key!="logs") {
                    map.set(key,receipt[key])
                }
            }

            const logs = []

            for (let  key in receipt.logs) {
                let  item = new Map();
                data = receipt.logs[key]
                for (let  key2 in data) {
                    item.set(key2,data[key2])
                }
                logs.push(item)
            }

            map.set("logs",logs)

            return map
        }
CODE
    
    def self.init_provider(rpc_node)
        @@semaphore.synchronize do
            Jscall.init_provider(rpc_node)
        end
    end

    def self.destroy_provider()
        @@semaphore.synchronize do
            Jscall.destroy_provider()
        end
    end

    def self.contract(abi,address)
        @@semaphore.synchronize do
            Jscall.init_contract(abi,address)
        end
    end

    def self.provider
        @@semaphore.synchronize do
            Jscall.provider
        end
    end

    def parallel(func, argv, concurrency=10)
        # generate key
        # match key in cache
        # unmatch key to call func parallel
        # write back to cache
        # return all
    end

    def parallelEx(func, argv, concurrency=10)
    end

    def self.getCode(address,block="latest")
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            @@semaphore.synchronize do
                Jscall.provider.getCode(address,block)
            end
        end
    end

    def self.getBlock(block)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            @@semaphore.synchronize do
                Jscall.getBlock(block)
            end
        end
    end

    def self.getBlockWithTransactions(block)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            @@semaphore.synchronize do
                Jscall.getBlockWithTransactions(block)
            end
        end
    end

    def self.getTransaction(txhash)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            @@semaphore.synchronize do
                Jscall.getTransaction(txhash)
            end
        end
    end

    def self.getTransactionReceipt(txhash)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            @@semaphore.synchronize do
                Jscall.getTransactionReceipt(txhash)
            end
        end
    end

    def self.getStorageAt(addr, pos, block="latest")
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            @@semaphore.synchronize do
                Jscall.provider.getStorageAt(txhash)
            end
        end
    end    

    def self.getBlockNumber()
        @@semaphore.synchronize do
            Jscall.provider.getBlockNumber()
        end
    end

    def self.getGasPrice()
        @@semaphore.synchronize do
            Jscall.provider.getGasPrice()
        end
    end

    def self.getContractCreationBlock(address)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            return nil if getCode(address)=="0x"
            latest = getBlockNumber()
            earliest = 0 
                
            ret =  _getContractCreationBlock(address,latest,earliest)
        end
    end

    def self._getContractCreationBlock(address,upper,lower)
        if upper-lower<=1 then
            return upper
        end

        mid = (upper+lower)/2
        if getCode(address,mid)=="0x" then
            _getContractCreationBlock(address,upper,mid)
        else
            _getContractCreationBlock(address,mid,lower)
        end
    end

    def self._decode_value(type,data)
        if type=="address" then
            "0x"+data[24,40]
        elsif type =~ /^uint/ then
            data.to_i(16)
        else type =~ /^int/
            size = type.gsub(/^int/,"").to_i  # 8
            data = data[64-size/4,size/4]   # ff
            sign_bit = 1 << (size-1)   # 10000000 & 80 = 80

            sign = data.to_i(16) & sign_bit == sign_bit ? -1 : 1

            if sign == 1 then
                value = data.to_i(16)
            else
                value = data.to_i(16) - 2**(size)
            end

            value
        end
    end
 
    def self.decode_event(topics,data)
        ret = {}
        topics_cp = 1
        data_cp = 2
        ret[:event_id] = topics[0]
        ret[:event], args_name = Contract.search_digest(ret[:event_id])
        if args_name then 
            args_name = args_name.split(",")
        else
            args_name = []
        end

        ret[:event_args] = []
        
        if ret[:event] then
            params = ret[:event].gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",")

            params.each_with_index do |param_type,i|
                _, indexed = args_name[i].split(":")
                if indexed then
                    param_data = topics[topics_cp].gsub(/^0x/,"")
                    topics_cp += 1
                else
                    param_data = data[data_cp,64]
                    data_cp += 64
                end
                ret[:event_args].push([param_type,args_name[i],_decode_value(param_type,param_data)])
            end
        end

        return ret
    end

    def self.decode_method(data)
        ret = {}
        return ret if data.nil?
        if data.size>=10 then
            cp = 0

            ret[:method_id] = data[cp,10]
            cp += 10

            ret[:method_name], args_name = Contract.search_digest(ret[:method_id])
            if args_name then 
                args_name = args_name.split(",")
            else
                args_name = []
            end

            ret[:method_args] = []
            
            if ret[:method_name] then
                params = ret[:method_name].gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",")

                params.each_with_index do |param_type,i|
                    param_data = data[cp,64]
                    cp += 64

                    ret[:method_args].push([param_type,args_name[i],_decode_value(param_type,param_data)])
                end
            end
        end
        return ret
    end


    def self.parseTxs(hash)
        Transaction.new(hash)
    end    
end


class Transaction
    attr_reader :parse, :tx_internal, :tx, :receipt

    def method_missing(name, *args)
        if @parse[name.to_sym] then
            return @parse[name.to_sym]
        else
            super
        end
    end

    def inspect
        @parse.pretty_inspect
    end

    def initialize(hash)
        @parse = {}
     
        Thread.wait(
            ->{@tx_internal = Etherscan.getTxInternal(hash)},
            ->{@tx = Web3.getTransaction(hash)

            @parse[:blockNumber] = @tx["blockNumber"]
            @block = Web3.getBlock(@parse[:blockNumber])    
            },
            ->{@receipt = Web3.getTransactionReceipt(hash)}
        )

        @parse[:blockTime] = Time.at(@block["timestamp"])
        @parse[:txHash] = @tx["hash"]
        @parse[:from] = @tx["from"]
        @parse[:to] = @tx["to"]
      
        if @tx["to"]==nil and @tx["creates"]!=0 then
            @parse[:type] = "contract_creation"
            @parse[:contract_address] = @tx["creates"]
            @parse[:method_name] = "[contract_creation]"
        else
            @parse.merge!(Web3.decode_method(@tx["data"])) 

            @parse[:type] = "method_call" if @parse[:method_id]!="0x"
        end 
        
      
        @parse[:status] = @receipt["status"] == 1 ? "success" : "failure"

        @parse[:logs] = @receipt["logs"].map do |log|
            {address:log["address"]}.merge(Web3.decode_event(log["topics"],log["data"]))
        end
        
        return self
    end
end