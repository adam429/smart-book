require 'smartbook/jscall'
require "minitest/autorun"

class TestJsCall < Minitest::Test  
    def test_multi_thread 
        Jscall.exec("""
            function sleep(ms) {
                return new Promise((resolve) => {
                  setTimeout(resolve, ms);
                });
              }        
        """)


        20.times do |x|
            Thread.new do Jscall.exec("sleep(500).then(()=>#{x})") end
        end
    end
end

