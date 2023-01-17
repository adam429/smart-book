require 'uri'
require 'net/http'
require 'keccak256'

require 'smartbook/file_cache'
require 'smartbook/jscall'
require 'smartbook/lazyexec'

module SmartBook

    class Etherscan 
        def self.api_key(key)
            @@etherscan_api_key = key
        end

        def self.getAddressTx(address)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do
                url = "https://api.etherscan.io/api?module=account&action=txlist&address=#{address}&startblock=0&endblock=99999999&page=0&offset=0&sort=asc&apikey=#{@@etherscan_api_key}"

                JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
            end
        end

        def self.getTxInternal(txhash)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do
                url = "https://api.etherscan.io/api?module=account&action=txlistinternal&txhash=#{txhash}&apikey=#{@@etherscan_api_key}"

                JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
            end
        end

        def self.getAbi(address,fallback_file=nil)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do
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
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do
                url = "https://api.etherscan.io/api?module=contract&action=getcontractcreation&contractaddresses=#{address}&apikey=#{@@etherscan_api_key}"

                JSON.load(Net::HTTP.get_response(URI(url)).body)["result"]
            end
        end        
        
        def self.getBlockNoByTime(timestamp)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do
                url = "https://api.etherscan.io/api?module=block&action=getblocknobytime&timestamp=#{timestamp.to_i}&closest=before&apikey=#{@@etherscan_api_key}"

                JSON.load(Net::HTTP.get_response(URI(url)).body)["result"].to_i
            end
        end        
    end

    class Web3 
        ## Skip cache for Web3
        FileCache.skip_cache do |key,value|
            (key.to_s).gsub(/\)$/,"").gsub(/^[^\(]+\(/,"").split(",").include?("latest")
        end

        FileCache.skip_cache do |key,value|
            value.class == Jscall::RemoteRef
        end

        def self.init_web3()

            Jscall.exec <<~CODE
                global.ethers = require('ethers')

                async function init_provider(rpc_node) {
                    global.provider = await new ethers.getDefaultProvider(rpc_node)        
                }

                async function destroy_provider(){
                    if (global.provider.destroy != null) {
                        await global.provider.destroy()            
                    }
                }

                async function init_contract(abi,address)
                {
                    return await new ethers.Contract(address, abi, global.provider)
                }

                function objectToMap(obj) {
                    const map = new Map();

                    for (let key in obj) {
                        if (obj[key]!=null && obj[key]._isBigNumber) {
                            obj[key] = obj[key].toString()
                        }
                        map.set(key,obj[key])
                    }

                    return map;
                }

                async function getTransaction(txhash)
                {
                    let tx = await global.provider.getTransaction(txhash);
                    
                    delete tx.wait
                    delete tx.accessList

                    return objectToMap(tx);
                }

                async function getBlockWithTransactions(blockno)
                {
                    let block = await global.provider.getBlockWithTransactions(blockno);

                    let map = objectToMap(block)

                    const transactions = []

                    for (let  key in block.transactions) {

                        data = block.transactions[key]

                        delete data.wait
                        delete data.accessList

                        transactions.push(objectToMap(data))
                    }

                    map.set("transactions",transactions)

                    return map
                }

                async function getBlock(blockno)
                {
                    let block = await global.provider.getBlock(blockno);

                    return objectToMap(block);                    
                }


                async function getTransactionReceipt(txhash)
                {
                    let receipt = await global.provider.getTransactionReceipt(txhash);
                    
                    let map = objectToMap(receipt)                    

                    const logs = []

                    for (let  key in receipt.logs) {
                        data = receipt.logs[key]
                        logs.push(objectToMap(data))
                    }

                    map.set("logs",logs)

                    return map
                }
                null
            CODE
        end

        def self.init_provider(rpc_node)
            Jscall.init_provider(rpc_node)
        end

        def self.destroy_provider()
            Jscall.destroy_provider()
        end

        def self.contract(abi,address)
            Jscall.init_contract(abi,address)
        end

        def self.provider
            Jscall.provider
        end

        def self.getBlockNumber()
            LazyExec.new(nil,"Jscall:global.provider.getBlockNumber()") 
        end

        def self.getGasPrice()
            LazyExec.new(nil,"Jscall:global.provider.getGasPrice().then((x)=>{return parseInt(x.toString())})") 
        end

        def self.encode_js(obj)
            return "'#{obj}'" if obj.class == String
            return obj 
        end

        def self.getCode(address,block="latest")
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })",
                "Jscall:global.provider.getCode(#{encode_js(address)},#{encode_js(block)})") 
        end

        def self.getBlock(block)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })",
                "Jscall:global.getBlock(#{encode_js(block)})" )
        end

        def self.getBlockWithTransactions(block)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })",
                "Jscall:global.getBlockWithTransactions(#{encode_js(block)})") 
        end

        def self.getTransaction(txhash)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })",
                "Jscall:global.getTransaction(#{encode_js(txhash)})") 
        end

        def self.getTransactionReceipt(txhash)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })",
                "Jscall:global.getTransactionReceipt(#{encode_js(txhash)})") 
        end

        def self.getStorageAt(addr, pos, block="latest")
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })",
                "Jscall:global.provider.getStorageAt(#{encode_js(addr)},#{encode_js(pos)},#{encode_js(block)})") 
        end    

        def self.getContractCreationBlock(address)
            LazyExec.new("#{__method__}(#{ method(__method__).parameters.filter{|t,_| t!=:block }.map{|_,v| binding.local_variable_get(v)}.join(",")  })") do            
                return nil if getCode(address)=="0x"
                latest = getBlockNumber().wait_value
                earliest = 0 
                    
                _getContractCreationBlock(address,latest,earliest)
            end
        end

        def self._getContractCreationBlock(address,upper,lower)
            # puts "#{address} #{upper} #{lower}"
            if upper-lower<=1 then
                return upper
            end

            mid = (upper+lower)/2
            if getCode(address,mid).wait_value =="0x" then
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

        Web3.init_web3()
    end


    class Contract 
        @@list = {}
        @@abi_mapping = FileCache.cache["abi_mapping"] || {}

        def self.list
            @@list
        end

        def self.abi_mapping
            @@abi_mapping
        end

        def self.add(name,abi,address)        
            abi = abi.class == LazyExec ? abi.wait_value : abi

            contract = Web3.contract(abi,address)
            @@list[name.to_sym] = 
                {
                    :contract => contract,
                    :ruby_obj => self.new(contract,name,address),
                    :abi => abi
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

            FileCache.write_cache("abi_mapping",@@abi_mapping)
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

        attr_reader :contract

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
            key = nil
            key = "#{@address}.#{@name}.#{name}(#{args.join(",")})" if args.last.class == Hash and args.last[:blockTag].to_i>0

            # jscall version to run parallel via LazyExec
            jscode = """Jscall:Ruby
                            .get_exported_imported()[0]
                            .objects[#{@contract.__get_id}][#{Web3.encode_js(name.to_s)}](#{args.map {|i| Web3.encode_js(i)}.join(",")})
                            .then( (x)=>{ 
                                if (x._isBigNumber) {
                                    return x.toString();
                                }
                                if (x instanceof Array) {
                                    return x.map( (y)=>{
                                        if (y._isBigNumber) {
                                            return y.toString();
                                        }
                                    });
                                }
                                return x;
                            } )"""
            LazyExec.new(key,jscode)

            # ruby version, single thread because the jscall is under semaphore
            # LazyExec.new(key) do
            #     ret = @contract.send(name,*args)
            #     ret = self.class.convertBigNumberToString(ret)
            #     ret
            # end                

        end
    end

    ## here

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
end