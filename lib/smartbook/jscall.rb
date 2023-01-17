require 'jscall'

module Jscall
    @@semaphore = Mutex.new

    def self.semaphore
        @@semaphore
    end

    class PipeToJsWithSemaphore < PipeToJs
        def send_command(cmd)
            Jscall.semaphore.synchronize do
                super(cmd)
            end
        end
    end

    @pipeToJsClass = PipeToJsWithSemaphore

    #def self.config(module_names: [], options: '', browser: false, sync: false)
    def self.config(**kw)
        if kw.nil? || kw == {}
            @configurations = {}
        else
            @configurations = @configurations.merge!(kw)
        end
        browser = @configurations[:browser]
        @pipeToJsClass = if browser then PipeToBrowser else PipeToJsWithSemaphore end
        nil
    end

end