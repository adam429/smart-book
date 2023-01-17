require 'smartbook/thread_wait'
require "minitest/autorun"

class TestThreadWait < Minitest::Test
    def test_thread_wait
        assert Thread.wait(->{1},->{2},->{3}) == [1,2,3]
    end
end
