require 'jscall'

# define a function in js
Jscall.exec <<-CODE
    async function test(x)
    {
        await new Promise(r => setTimeout(r, 1000));
        return x
    }
CODE


# concurrent call in js
Jscall.exec <<-CODE
    async function parallel() {
        let p = []
        for (var i=1;i<=20;i++) {
            p.push(test(i))
        }
        return await Promise.all(p)
    }
CODE
ret1 = Jscall.parallel()

puts ret1.to_s
# output [1,2,3,4,5 ... , 20], ok


# non-concurrent call in ruby
ret2 = (1..20).to_a.map do |x|
    Jscall.test(x)
end
puts ret2.to_s
# output [1,2,3,4,5 ... , 20], ok



# concurrent call in ruby
ret3 = (1..20).to_a.map do |x|
    Thread.new do
        Jscall.test(x)
    end
end.map(&:value)

puts ret3.to_s
# except [1,2,3,4,5 ... , 20], but error