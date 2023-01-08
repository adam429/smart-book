require 'fileutils'
require "minitest/autorun"
require 'smartbook/persistence'

class TestPersistence < Minitest::Test  
    def test_array
        code = SmartBook::Persistence.to_opal([1,2,3],"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo!=[1,2,3]
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        assert `opal .tmp/test.rb` == "ok\n"        
    end

    def test_hash
        code = SmartBook::Persistence.to_opal({:a=>1,:b=>2},"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo!={:a=>1,:b=>2}
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        assert `opal .tmp/test.rb` == "ok\n"        
    end

    def test_hash_array
        code = SmartBook::Persistence.to_opal({:a=>[1,2,3],:b=>[{:c=>5,:d=>6}]},"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo!={:a=>[1,2,3],:b=>[{:c=>5,:d=>6}]}
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        assert `opal .tmp/test.rb` == "ok\n"        
    end

    class Foo < SmartBook::Persistence
        attr_accessor :value

        def initialize(value)
            @value = value
        end

        def to_json(*args)
            {
                JSON.create_id  => self.class.name,
                :data           => @value
            }.to_json(*args)
        end           
        
        def self.json_create(object)
            self.new(self.symbolize_names(object)[:data])
        end            
    end

    def test_persistence_class
        code = SmartBook::Persistence.to_opal(Foo.new(1),"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo.value!=1
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        # assert `opal .tmp/test.rb` == "ok\n"        

        # todo: failure - need json create object in opal
    end

end