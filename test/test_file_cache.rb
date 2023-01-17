require 'smartbook/file_cache'
require 'fileutils'
require "minitest/autorun"

class TestFileCache < Minitest::Test  
    def init
        SmartBook::FileCache.skip_cache = []
        SmartBook::FileCache.clear_cache()
        begin
            FileUtils.remove_file(".cache")
        rescue 
        end
    end
    
    def test_create_clear_cache
        init()
        SmartBook::FileCache.write_cache("key","value")
        assert SmartBook::FileCache.read_cache("key")=="value"

        SmartBook::FileCache.write_cache("key",123)        
        assert SmartBook::FileCache.read_cache("key")==123
        assert SmartBook::FileCache.has_key?("key") == true

        SmartBook::FileCache.delete_cache("key")
        assert SmartBook::FileCache.read_cache("key")==nil
        assert SmartBook::FileCache.has_key?("key") == false

        SmartBook::FileCache.write_cache("key",[1,2,3])        
        assert SmartBook::FileCache.read_cache("key")==[1,2,3]

        SmartBook::FileCache.write_cache("key",{a:1,b:2})        
        assert SmartBook::FileCache.read_cache("key")=={a:1,b:2}

        # test clear cache
        SmartBook::FileCache.clear_cache()
        assert SmartBook::FileCache.read_cache("key")==nil
        SmartBook::FileCache.load_cache()        
        assert SmartBook::FileCache.read_cache("key")==nil
    end

    def test_enable_disable_cache
        init()
        SmartBook::FileCache.stop_cache

        SmartBook::FileCache.write_cache("key","value")
        assert SmartBook::FileCache.read_cache("key") == nil
        assert SmartBook::FileCache.has_key?("key") == false

        SmartBook::FileCache.start_cache

        SmartBook::FileCache.write_cache("key","value")
        assert SmartBook::FileCache.read_cache("key")=="value"
        assert SmartBook::FileCache.has_key?("key") == true

    end

    def test_save_load_cache
        init()
        SmartBook::FileCache.write_cache("key","value")
        SmartBook::FileCache.cache = {}

        assert SmartBook::FileCache.read_cache("key")==nil
        assert SmartBook::FileCache.has_key?("key") == false
        SmartBook::FileCache.load_cache()     
        assert SmartBook::FileCache.read_cache("key")=="value"
        assert SmartBook::FileCache.has_key?("key") == true
        
    end

    def test_cache_size
        init()
        size1 = SmartBook::FileCache.cache_size
        SmartBook::FileCache.write_cache("key","value")
        size2 = SmartBook::FileCache.cache_size
        SmartBook::FileCache.write_cache("key","value")
        size3 = SmartBook::FileCache.cache_size
        SmartBook::FileCache.write_cache("key2",123)
        size4 = SmartBook::FileCache.cache_size

        assert size1<size2
        assert size2<=size3
        assert size3<size4
    end

    def test_skip_cache
        init()
        SmartBook::FileCache.skip_cache do |key,value|
            key =~ /key0/
        end

        SmartBook::FileCache.write_cache("key0","value")
        SmartBook::FileCache.write_cache("key1","value")
        SmartBook::FileCache.write_cache("key2","value")

        assert SmartBook::FileCache.has_key?("key0")==false
        assert SmartBook::FileCache.has_key?("key1")==true
        assert SmartBook::FileCache.has_key?("key2")==true


        init()
        SmartBook::FileCache.skip_cache do |key,value|
            value.is_a?(String)
        end
        SmartBook::FileCache.skip_cache do |key,value|
            value.is_a?(Hash)
        end

        SmartBook::FileCache.write_cache("key0","value")
        SmartBook::FileCache.write_cache("key1",123)
        SmartBook::FileCache.write_cache("key2",[1,2,3])
        SmartBook::FileCache.write_cache("key3",{a:"value"})

        assert SmartBook::FileCache.has_key?("key0")==false
        assert SmartBook::FileCache.has_key?("key1")==true
        assert SmartBook::FileCache.has_key?("key2")==true
        assert SmartBook::FileCache.has_key?("key3")==false
    end

    def test_cache_file
        init()
        SmartBook::FileCache.cache_file = ".another_cache"
        SmartBook::FileCache.write_cache("key","value")
        assert File.exist?(".another_cache") == true
        assert File.exist?(".cache") == false

        FileUtils.remove_file(".another_cache")
        SmartBook::FileCache.cache_file = ".cache"
        SmartBook::FileCache.save_cache
        assert File.exist?(".another_cache") == false
        assert File.exist?(".cache") == true
    end

    def read_write_count 
        init()
        assert SmartBook::FileCache.write_count("key") == 0
        assert SmartBook::FileCache.read_count("key") == 0

        time = Time.now
        SmartBook::FileCache.write_cache("key","value")

        assert SmartBook::FileCache.write_count("key") == 1
        assert SmartBook::FileCache.read_count("key") == 0
        assert SmartBook::FileCache.write_time("key") - time < 1
        assert SmartBook::FileCache.read_time("key") == 0

        time = Time.now
        SmartBook::FileCache.write_cache("key",123)

        assert SmartBook::FileCache.write_count("key") == 2
        assert SmartBook::FileCache.read_count("key") == 0
        assert SmartBook::FileCache.write_time("key") - time < 1
        assert SmartBook::FileCache.read_time("key") == 0

        time = Time.now
        SmartBook::FileCache.read_cache("key")

        assert SmartBook::FileCache.write_count("key") == 2
        assert SmartBook::FileCache.read_count("key") == 1
        assert SmartBook::FileCache.read_time("key") - time < 1

        time = Time.now
        SmartBook::FileCache.read_cache("key")

        assert SmartBook::FileCache.write_count("key") == 2
        assert SmartBook::FileCache.read_count("key") == 2
        assert SmartBook::FileCache.read_time("key") - time < 1
    end

end