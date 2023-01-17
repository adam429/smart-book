require 'jscall'
require 'parallel'

Jscall.exec <<CODE
    const { PromisePool } = require('@supercharge/promise-pool')

    async function test(x)
    {
        await new Promise(r => setTimeout(r, 1000));
        return x
    }

    function getObj() {
        return {test:test}
    }

    async function parallel(obj,func, argv, concurrency=10)
    {
        return (await PromisePool.for(argv).withConcurrency(concurrency).process(async item => {
            if (obj==null) { obj = global }
            return await obj[func](item)
          })).results
    }

    async function parallelEx(obj,func, argv, concurrency=10)
    {
        return (await PromisePool.for([...Array(obj.length).keys()]).withConcurrency(concurrency).process(async index => {
            if (obj[index]==null) { obj[index] = global }
            return await obj[index][func[index]](argv[index])
          })).results
    }

    async function multiExec(argv, concurrency=10)
    {
        return (await PromisePool.for(argv).withConcurrency(concurrency).process(async item => {
            return eval(item)
          })).results
    }

CODE

time = Time.now
    puts Jscall.parallel(nil, "test",(1..20).to_a).to_s
puts "time: #{Time.now-time}s"


time = Time.now
    puts Jscall.parallelEx([nil]*20, ["test"]*20,(1..20).to_a).to_s
puts "time: #{Time.now-time}s"


module Jscall
    def self.multi_exec(*argv)
        Jscall.multiExec(argv)        
    end
end

time = Time.now

puts Jscall.multi_exec(
    "test(1)",
    "test(2)",
    "test(3)",
    "test(4)",
    "test(5)",
    "test(6)",
    "test(7)",
    "test(8)",
    "test(9)",
    "test(10)",
    "test(11)",
    "test(12)",
    "test(13)",
    "test(14)",
    "test(15)",
    "test(16)",
    "test(17)",
    "test(18)",
    "test(19)",
    "test(20)",
).to_s

puts "time: #{Time.now-time}s"

# Parallel.map((1..20).to_a, in_threads: 5) do |x|
#     puts "thread #{Thread.current.object_id} - begin x:#{x}"
#     Jscall.test(x)
#     puts "thread #{Thread.current.object_id} - end x:#{x}"
# end


