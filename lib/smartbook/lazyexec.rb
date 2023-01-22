require 'smartbook/jscall'
require 'smartbook/file_cache'
require 'smartbook/thread_wait'

module SmartBook

    class LazyExec 
        @@cache = FileCache

        def self.init_jscall()  
            Jscall.exec <<~CODE
                if (global.multiExec == undefined) {
                    global.multiExec = async function (argv)
                    {
                        return await Promise.all(argv.map(async item => {
                            return eval(item)
                        }))
                    }
                }
            CODE
        end

        # Jscall.exec <<~CODE
        #     const { PromisePool } = require('@supercharge/promise-pool')

        #     async function multiExec(argv, concurrency=10)
        #     {
        #         return (await PromisePool.for(argv).withConcurrency(concurrency).process(async item => {
        #             return eval(item)
        #         })).results
        #     }
        # CODE

        def initialize(key=nil,eval=nil,&block)
            @key = key
            @eval = eval
            @block = block
            @exec = false
            @value = nil

            ## load from cache to skip exec
            if @@cache.has_key?(key) then
                @value = @@cache.read_cache(key)
                @exec = true
            end

        end

        def exec?
            return @exec
        end

        def exec
            return if @exec

            if @block!=nil then
                update_value(@block.call)
            elsif @eval!=nil then
                if type=="Jscall" then
                    self.class.init_jscall
                    value = Jscall.exec(code)
                    update_value(value)
                end
                if type=="Ruby"
                    update_value(eval(code))
                end
            end
        end

        def update_value(value)
            @exec = true
            @value = value
            @@cache.write_cache(@key,@value)
        end

        # nonblock to get value
        def value
            if @exec == true then
                return @value
            else
                return self
            end
        end

        # block to wait value
        def wait_value
            if @exec == true then
                return @value
            else
                exec
                return @value
            end
        end

        def then(proc=nil,&block)
            if block and proc==nil then
                return self.class.new(nil) do
                    block.call(self.wait_value)
                end
            end
            if block==nil and proc then
                return self.class.new(nil) do
                    proc.call(self.wait_value)
                end
            end
        end

        def type
            return "Jscall" if @eval =~ /^Jscall:/
            return "Ruby"
        end

        def code
            return @eval if type == "Ruby"
            return @eval.gsub(/^Jscall:/,"") if type == "Jscall"
        end

        def self.wait_value(lazyexec)
            self.all(lazyexec).wait_value
        end

        def self.all(lazyexec)
            if lazyexec.class == LazyExec then
                return lazyexec
            end

            if lazyexec.class == Array then
                return self.new(nil) do    
                    multi_jscall = []
                    multi_lazyexec = []
    
    
                    lazyexec.each_with_index do |item,i|
                        if item.type=="Jscall" and item.value.class == self then
                            multi_jscall.push({index:i,code:item.code})
                        else
                            multi_lazyexec.push({index:i,value:item})
                        end
                    end
    
                    proc_jscall = ->{
                        if multi_jscall.size>0 then
                            self.init_jscall
                            result_js = Jscall.multiExec(multi_jscall.map {|x| x[:code]}) 

                            multi_jscall.each_with_index do |x,i|
                                lazyexec[x[:index]].update_value(result_js[i])
                            end
                        end
                    }
    
                    Thread.wait(proc_jscall, *multi_lazyexec.map {|x| Proc.new { x[:value].wait_value } })
    
                    # return Thread.wait(*lazyexec.map {|x| Proc.new { x.wait_value } })
                    lazyexec.map {|x| x.wait_value}
                end                
            end
        end        

        def to_i
            wait_value.to_i
        end

        def to_s
            wait_value.to_i
        end
    end

end