require 'json'  
require 'pp'

module SmartBook

    class Cache
        @@enable = true
        @@skip_cache = []
        @@semaphore = Mutex.new


        def self.stop_cache
            @@enable = false
        end

        def self.start_cache
            @@enable = true
        end

        def self.skip_cache(&block)
            @@skip_cache.push(block) if block
            @@skip_cache
        end

        def self.skip_cache=(skip_cache)
            @@skip_cache = skip_cache
        end

        def self.write_cache(key,value)
            return unless key
            return unless @@enable 
            @@skip_cache.each do |skip_block|
                # skip write cache if need any of these conditions
                return if skip_block.call(key,value)
            end
            
            cache_value = _read_cache(key)
            cache_value = {} unless cache_value
            cache_value["v"] = value
            cache_value["wc"] = 0 unless cache_value.has_key?("wc")
            cache_value["wc"] = cache_value["wc"] + 1
            cache_value["wt"] = Time.now.to_i

            _write_cache(key,cache_value) 
        end

        def self.read_cache(key)
            cache_value = _read_cache(key)
            return nil unless cache_value
            
            cache_value["rc"] = 0 unless cache_value.has_key?("rc")
            cache_value["rc"] = cache_value["rc"] + 1
            cache_value["rt"] = Time.now.to_i
            _write_cache(key,cache_value)

            return cache_value["v"]
        end

        def self.read_count(key)
            cache_value = _read_cache(key)
            return 0 unless cache_value
            return 0 unless cache_value.has_key?("rc")
            return cache_value["rc"] if cache_value.has_key?("rc")
        end

        def self.write_count(key)
            cache_value = _read_cache(key)
            return 0 unless cache_value
            return 0 unless cache_value.has_key?("wc")
            return cache_value["wc"] if cache_value.has_key?("wc")
        end

        def self.read_time(key)
            cache_value = _read_cache(key)
            return 0 unless cache_value
            return 0 unless cache_value.has_key?("rt")
            return cache_value["t"] if cache_value.has_key?("rt")
        end

        def self.write_time(key)
            cache_value = _read_cache(key)
            return 0 unless cache_value
            return 0 unless cache_value.has_key?("wt")
            return cache_value["wt"] if cache_value.has_key?("wt")
        end

        def self.save_cache(force=false)
            if force then
                # force save cache
                @@semaphore.synchronize do
                    _save_cache
                end
            else
                # lazy save cache
                Thread.new do
                    lazy_time = 1

                    @@save_cache_thread = Thread.current.object_id
                    sleep(lazy_time)
                    if @@save_cache_thread == Thread.current.object_id then
                        @@semaphore.synchronize do
                            _save_cache
                        end
                    end
                end            
            end
        end

        def self.load_cache
        end

        def self.cache_size
        end

        def self.delete_cache(key)
        end

        def self.has_key?(key)
        end

        def self.clear_cache
        end

        def self.filter(conditions,&block)          
        end
    end

    class FileCache < Cache
        @@cache = {}
        @@cache_file = ".cache"

        def self.cache
            @@cache
        end

        def self.cache=(cache)
            @@cache=cache
        end

        def self.cache_file
            @@cache_file
        end

        def self.cache_file=(file)
            @@cache_file=file
        end

        def self._save_cache
            # puts "Saving cache to #{@@cache_file}"
            data = JSON.pretty_generate(@@cache)
            File.open(@@cache_file,"w") do |file|
                file.write(data)
            end
        end

        def self.load_cache
            begin
                @@cache = JSON.load(File.open(@@cache_file,"r").read())
            rescue
            end
        end

        def self.cache_size
            JSON.generate(@@cache).size
        end

        def self.delete_cache(key)
            @@cache.delete(key)
            self.save_cache
        end

        def self.has_key?(key)
            return @@cache.has_key?(key)
        end

        def self._read_cache(key)
            return @@cache[key]
        end

        def self.clear_cache
            @@cache = {}
            self.save_cache
        end

        def self._write_cache(key,value)
            @@cache[key] = value
            self.save_cache
        end

        def self.filter(conditions,&block)          
            @@cache.each do |key,value|
                block.call(key,value) if key =~ conditions
            end
        end
    end
end