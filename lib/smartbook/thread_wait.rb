require 'thread'

class Thread
    def self.wait(*args)
        args.map {|x| Thread.new(&x) }.map {|x| x.join }.map {|x| x.value}
    end
end
