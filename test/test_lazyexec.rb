require 'smartbook/lazyexec'
require "minitest/autorun"

class TestLazyExec < Minitest::Test

    def init
        SmartBook::FileCache.skip_cache = []
        SmartBook::FileCache.clear_cache()
        begin
            FileUtils.remove_file(".cache")
        rescue 
        end
    end

    def test_lazy_exec_ruby
        init

        lazyexec = SmartBook::LazyExec.new(nil,"sleep(0.5); 123")

        assert lazyexec.value.class == SmartBook::LazyExec
        assert lazyexec.exec? == false

        time = Time.now; lazyexec.exec
        assert lazyexec.exec? == true
        assert Time.now-time > 0.5

        time = Time.now; lazyexec.exec
        assert Time.now-time < 0.01
        time = Time.now; lazyexec.exec
        assert Time.now-time < 0.01

        assert lazyexec.value == 123
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time < 0.01

        # -----------------


        lazyexec = SmartBook::LazyExec.new(nil) do
            sleep(0.5)
            123
        end
        assert lazyexec.exec? == false
        
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time > 0.5
        assert lazyexec.exec? == true

        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time < 0.01
    end

    def test_lazy_exec_jscall
        init

        lazyexec = SmartBook::LazyExec.new(nil,"Jscall:123")
        assert lazyexec.wait_value == 123

        Jscall.exec("function test() { return 123 }")
        lazyexec = SmartBook::LazyExec.new(nil,"Jscall:test()")
        assert lazyexec.wait_value == 123
    end

    def test_cache
        init

        lazyexec = SmartBook::LazyExec.new("key0") do 
            sleep(0.5)
            123
        end
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time > 0.5

        lazyexec = SmartBook::LazyExec.new("key0") do 
            sleep(0.5)
            456
        end
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time < 0.01


        # -----------------
        lazyexec = SmartBook::LazyExec.new("key1","sleep(0.5);123")
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time > 0.5

        lazyexec = SmartBook::LazyExec.new("key1","sleep(0.5);456")
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time < 0.01        


        # -----------------
        Jscall.exec("""
            function sleep(ms) {
                return new Promise((resolve) => {
                  setTimeout(resolve, ms);
                });
              }        
        """)

        lazyexec = SmartBook::LazyExec.new("key2","Jscall:sleep(500).then(()=>123)")
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time > 0.5

        lazyexec = SmartBook::LazyExec.new("key2","Jscall:sleep(500).then(()=>456)")
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time < 0.01       

        lazyexec = SmartBook::LazyExec.new("key3","Jscall:(async ()=>{await sleep(500); return 123})()")
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time > 0.5

        lazyexec = SmartBook::LazyExec.new("key3","Jscall:(async ()=>{await sleep(500); return 123})()")
        time = Time.now; 
        assert lazyexec.wait_value == 123
        assert Time.now-time < 0.01

    end

    def test_then
        lazyexec = SmartBook::LazyExec.new(nil,"sleep(0.5); 123").then do |x| x+1 end
        assert lazyexec.wait_value == 124

        lazyexec = SmartBook::LazyExec.new(nil,"sleep(0.5); 123").then(->(x){x+1})
        assert lazyexec.wait_value == 124

    end

    def test_multi_wait
        init

        Jscall.exec("""
            function sleep(ms) {
                return new Promise((resolve) => {
                  setTimeout(resolve, ms);
                });
              }        
        """)

        # multi wait with single lazyexec
        lazyexec = SmartBook::LazyExec.new(nil,"Jscall:123")
        assert lazyexec.wait_value == 123
        assert SmartBook::LazyExec.wait_value(lazyexec) == 123
        
        # multi wait with array of same block
        le1 = SmartBook::LazyExec.new do sleep(0.5); 1 end
        le2 = SmartBook::LazyExec.new do sleep(0.5); 2 end
        le3 = SmartBook::LazyExec.new do sleep(0.5); 3 end
        time = Time.now; 
        assert SmartBook::LazyExec.wait_value([le1,le2,le3]) == [1,2,3]
        assert Time.now-time > 0.5
        assert Time.now-time < 0.6

        # multi wait with array of same ruby_eval
        le1 = SmartBook::LazyExec.new(nil,"sleep(0.5); 1")
        le2 = SmartBook::LazyExec.new(nil,"sleep(0.5); 2")
        le3 = SmartBook::LazyExec.new(nil,"sleep(0.5); 3")
        time = Time.now; 
        assert SmartBook::LazyExec.wait_value([le1,le2,le3]) == [1,2,3]
        assert Time.now-time > 0.5
        assert Time.now-time < 0.6

        # multi wait with array of same jscall_eval
        le1 = SmartBook::LazyExec.new(nil,"Jscall:(async ()=>{await sleep(500); return 1})()")
        le2 = SmartBook::LazyExec.new(nil,"Jscall:(async ()=>{await sleep(500); return 2})()")
        le3 = SmartBook::LazyExec.new(nil,"Jscall:(async ()=>{await sleep(500); return 3})()")
        time = Time.now; 
        assert SmartBook::LazyExec.wait_value([le1,le2,le3]) == [1,2,3]
        assert Time.now-time > 0.5
        assert Time.now-time < 0.6

        # multi wait with array of mix different type
        le1 = SmartBook::LazyExec.new do sleep(0.5); 1 end
        le2 = SmartBook::LazyExec.new(nil,"sleep(0.5); 2")
        le3 = SmartBook::LazyExec.new(nil,"Jscall:(async ()=>{await sleep(500); return 3})()")
        time = Time.now; 
        assert SmartBook::LazyExec.wait_value([le1,le2,le3]) == [1,2,3]
        assert Time.now-time > 0.5
        assert Time.now-time < 0.6

        # multi wait with index
        le1 = SmartBook::LazyExec.new("key0") do sleep(0.5); 1 end
        le2 = SmartBook::LazyExec.new("key1","sleep(0.5); 2")
        le3 = SmartBook::LazyExec.new("key2","Jscall:(async ()=>{await sleep(500); return 3})()")
        time = Time.now; 
        assert SmartBook::LazyExec.all([le1,le2,le3]).wait_value == [1,2,3]
        assert Time.now-time > 0.5
        assert Time.now-time < 0.6

        le1 = SmartBook::LazyExec.new("key0") do sleep(0.5); 1 end
        le2 = SmartBook::LazyExec.new("key1","sleep(0.5); 2")
        le3 = SmartBook::LazyExec.new("key2","Jscall:(async ()=>{await sleep(500); return 3})()")
        time = Time.now; 
        assert SmartBook::LazyExec.all([le1,le2,le3]).wait_value == [1,2,3]
        assert Time.now-time < 0.01

        le1 = SmartBook::LazyExec.new("key0") do sleep(0.5); 1 end
        le2 = SmartBook::LazyExec.new("key1","sleep(0.5); 2")
        le3 = SmartBook::LazyExec.new("key2","Jscall:(async ()=>{await sleep(500); return 3})()")
        assert SmartBook::LazyExec.all(le1).wait_value == 1
        assert SmartBook::LazyExec.all(le2).wait_value == 2
        assert SmartBook::LazyExec.all(le3).wait_value == 3
    end
end
