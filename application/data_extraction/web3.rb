require 'objspace'
require 'json'  
require 'uri'
require 'net/http'
require 'jscall'
require 'keccak256'
require 'pp'

class FileCache
    @@cache = {}

    def self.cache
        @@cache
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
        ret = block.call
        @@cache[key] = ret
        self.save_cache

        return ret
    end

    def self.update_cache(key,&block)
        return block.call if key.gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",").include?("latest")
        return @@cache[key] if @@cache.has_key?(key)

        ret = block.call
        @@cache[key] = ret
        self.save_cache

        return ret
    end

    def self.delete_cache(key)
        @@cache.delete(key)
        self.save_cache
    end
end

FileCache.restore_cache

class Web3 < FileCache

    def self.update_cache(key,&block)
        return block.call if key.gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",").include?("latest")
        return @@cache[key] if @@cache[key]

        ret = block.call
        @@cache[key] = ret
        self.save_cache

        return ret
    end

    def self.delete_cache(key)
        @@cache.delete(key)
        self.save_cache
    end
end

FileCache.restore_cache

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
                :ruby_obj => self.new(contract,name),
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
            name = x["inputs"].map {|i| i["name"]}.join(",")
            digest = "0x"+Digest::Keccak256.new.hexdigest(str)
            @@abi_mapping[digest] = [str,name]
        end

        force_update_cache(:abi_mapping) do
            @@abi_mapping
        end
    end

    def self.search_digest(digest)
        @@abi_mapping[digest] if @@abi_mapping[digest]

        ## todo search in 4byte.directory api
    end

    def self.method_missing(name, *args)
        if @@list[name.to_sym] then
            return @@list[name.to_sym][:ruby_obj]
        else
            super
        end
    end

    def initialize(contract,name)
        @contract = contract
        @name = name
    end

    def method_missing(name, *args)
        # puts name
        # puts args
        # puts args.last.class
        # puts args.last.class == Hash and args.last[:blockTag].to_i>0
        # puts "#{@contract.address}.#{@name}.#{name}(#{args.join(",")})"

        if args.last.class == Hash and args.last[:blockTag].to_i>0 then
            # puts "cache"
            self.class.update_cache("#{@contract.address}.#{@name}.#{name}(#{args.join(",")})") do    
                @contract.send(name,*args)
            end
        else
            # puts "no cache"
            @contract.send(name,*args)
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
            url = "https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp=#{timestamp}&closest=before&apikey=#{@@etherscan_api_key}"

            ret = JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
        end
    end        

end

class Web3 < FileCache
    Jscall.exec <<CODE
        global.ethers = require('ethers')

        async function init_provider(rpc_node) {
            global.provider = new ethers.getDefaultProvider(rpc_node)        
        }

        async function init_contract(abi,address)
        {
            return new ethers.Contract(address, abi, global.provider)
        }

        async function getTransaction(txhash)
        {
            tx = await global.provider.getTransaction(txhash);

            const map = new Map();

            for (var key in tx) {
                if (tx[key]!=null && tx[key]._isBigNumber) {
                    tx[key] = tx[key].toString()
                }
                map.set(key,tx[key])
            }

            return map
        }

        async function getTransactionReceipt(txhash)
        {
            receipt = await global.provider.getTransactionReceipt(txhash);
            
            const map = new Map();

            for (var key in receipt) {
                if (receipt[key]!=null && receipt[key]._isBigNumber) {
                  receipt[key] = receipt[key].toString()
                }
                if (key!="logs") {
                    map.set(key,receipt[key])
                }
            }

            const logs = []

            for (var key in receipt.logs) {
                var item = new Map();
                data = receipt.logs[key]
                for (var key2 in data) {
                    item.set(key2,data[key2])
                }
                logs.push(item)
            }

            map.set("logs",logs)

            return map
        }
CODE



    def self.init_provider(rpc_node)
        Jscall.init_provider(RPC_NODE)
    end

    def self.contract(abi,address)
        Jscall.init_contract(abi,address)
    end

    def self.provider
        Jscall.provider
    end

    def self.getCode(address,block="latest")
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            Jscall.provider.getCode(address,block)
        end
    end

    def self.getTransaction(txhash)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            Jscall.getTransaction(txhash)
        end
    end

    def self.getTransactionReceipt(txhash)
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            Jscall.getTransactionReceipt(txhash)
        end
    end

    def self.getStorageAt(addr, pos, block="latest")
        self.update_cache("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do    
            Jscall.provider.getStorageAt(txhash)
        end
    end    

    def self.getBlockNumber()
        Jscall.provider.getBlockNumber()
    end

    def self.getGasPrice()
        Jscall.provider.getGasPrice()
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
        # puts "upper: #{upper}, lower: #{lower}, mid: #{(upper+lower)/2}, diff: #{upper-lower}"

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
            value = (2**size-1-sign_bit) & data.to_i(16) # 01111111 & ff = 7f

            data.to_i(16) == sign_bit ? -1 * 2**(size-1) : sign*value
        end


        #     ret[param_type] = param_data.hex
        # elsif param_type=="bytes32" then
        #     ret[param_type] = "0x"+param_data
        # elsif param_type=="bool" then
        #     ret[param_type] = param_data.hex.to_i == 1 ? true : false
        # else
        #     ret[param_type] = param_data
    end

    def self.decode_event(topics,data)
        ret = {}
        topics_cp = 1
        data_cp = 0
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
                if topics_cp<topics.size then
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

            ret[:method], args_name = Contract.search_digest(ret[:method_id])
            if args_name then 
                args_name = args_name.split(",")
            else
                args_name = []
            end

            ret[:method_args] = []
            
            if ret[:method] then
                params = ret[:method].gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",")

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

    def blockNumber 
        @tx["blockNumber"]
    end


    def initialize(hash)
        @parse = {}
      
        @tx_internal = Etherscan.getTxInternal(hash)
        @tx = Web3.getTransaction(hash)
        @receipt = Web3.getTransactionReceipt(hash)
      
        if @tx["to"]==nil and @tx["creates"]!=0 then
            @parse[:type] = "contract_creation"
            @parse[:contract_address] = @tx["creates"]
        end 
        
        @parse.merge!(Web3.decode_method(@tx["data"]))

        @parse[:type] = "method_call" if @parse[:method_id]!="0x"
      
        @parse[:status] = @receipt["status"] == 1 ? "success" : "failure"

        @parse[:logs] = @receipt["logs"].map do |log|
            Web3.decode_event(log["topics"],log["data"])
        end

        return self
    end
end