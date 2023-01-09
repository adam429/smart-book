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
            self.add_import(self)
            {
                JSON.create_id  => self.class.name,
                :data           => @value
            }.to_json(*args)
        end           
        
        def self.json_create(object)
            self.new(self.symbolize_names(object)[:data])
        end            
    end

    class Bar < Foo
    end

    def test_persistence_class
        # Object Persistence
        code = SmartBook::Persistence.to_opal(Foo.new(1),"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo.value!=1
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        assert `opal .tmp/test.rb` == "ok\n"        



        # Object Persistence
        code = SmartBook::Persistence.to_opal(Foo.new([1,2,3,{:a=>4,:b=>5}]),"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo.value!=[1,2,3,{:a=>4,:b=>5}]
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        assert `opal .tmp/test.rb` == "ok\n"        



        # Object Persistence with another Object in value
        a = Foo.new(1)
        b = Foo.new(2)
        c = Bar.new({a:a,b:b})

        code = SmartBook::Persistence.to_opal(c,"foo")
        code = "require 'json'\n" + code
        code = code + <<~CODE
            puts "error" if foo.value[:a].value!=1
            puts "error" if foo.value[:b].value!=2
            puts "ok"
        CODE

        FileUtils.mkdir_p(".tmp")
        File.open(".tmp/test.rb","w") do |file| file.write(code) end
        assert `ruby .tmp/test.rb` == "ok\n"        
        assert `opal .tmp/test.rb` == "ok\n"        

    end

end