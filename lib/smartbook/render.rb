require 'webrick'
require 'erb'
require 'opal'
require 'opal-browser'

require 'smartbook/source_code'

module SmartBook

    module Render

        class Binding
            def initialize(vars,render)
                @__render = render
                vars.each do |k,v|
                    instance_variable_set("@#{k}", v)
                end
            end
            def get_binding
                binding
            end
            def get_render
                @__render
            end
        end

        class Render       
            @@server = nil 
            @@first_render = nil
            @@last_render = nil

            attr_accessor :body, :head, :js, :opal, :opal_require, :file
            attr_accessor :opal_before_code, :opal_after_code
            attr_accessor :opal_before_code_lazy, :opal_after_code_lazy


            def initialize
                @body = []
                @head = []
                @js = []
                @opal = []
                @opal_require = ["opal","promise","native","browser"]
                @opal_before_code = {:default=>[]}
                @opal_after_code = {:default=>[]}
                @opal_before_code_lazy = {:default=>[]}
                @opal_after_code_lazy = {:default=>[]}
            end


            def body(html,vars={})    
                @body.push(ERB.new(html).result(Binding.new(vars,self).get_binding))
            end

            def head(html)
                @head.push(html)
            end

            def js(js)
                @js.push(js)
            end

            def opal(opal)
                @opal.push(opal)
            end

            def add_opal_before_code(opal,key=:default)
                if key==:default then
                    @opal_before_code[key].push(opal) 
                else
                    @opal_before_code[key]=opal

                end
            end

            def add_opal_after_code(opal,key=:default)
                if key==:default then
                    @opal_after_code[key].push(opal)
                else
                    @opal_after_code[key]=opal
                end
            end

            def add_opal_before_code_lazy(key=:default, &opal)
                if key==:default then
                    @opal_before_code_lazy[key].push(opal) 
                else
                    @opal_before_code_lazy[key]=opal
                end
            end

            def add_opal_after_code_lazy(key=:default, &opal)
                if key==:default then
                    @opal_after_code_lazy[key].push(opal)
                else
                    @opal_after_code_lazy[key]=opal
                end
            end


            def opal_load_code(symbol)
                opal(symbol.source_code)
            end

            def opal_require(opal_req)
                @opal_require.push(opal_req)
            end

            def output
                # puts "@body=#{@body}"
                # puts "VarBinding.global=#{ SmartBook::Widget::VarBinding.global}"
                # puts "@opal_before_code=#{@opal_before_code}"
                # puts "@opal_after_code=#{@opal_after_code}"
                # puts "@opal_before_code_lazy=#{@opal_before_code_lazy}"
                # puts "@opal_after_code_lazy=#{@opal_after_code_lazy}"

                @opal_compile = []

                _opal_before_code = @opal_before_code.map do |k,v|
                    if k==:default then
                        v.join("\n")
                    else
                        v
                    end
                end.filter do |x| x!="" end

                _opal_after_code = @opal_after_code.map do |k,v|
                    if k==:default then
                        v.join("\n")
                    else
                        v
                    end
                end.filter do |x| x!="" end


                _opal_before_code_lazy = @opal_before_code_lazy.map do |k,v|
                    if k==:default then
                        v.map {|x| x.call}.join("\n")
                    else
                        v.call
                    end
                end.filter do |x| x!="" end

                _opal_after_code_lazy = @opal_after_code_lazy.map do |k,v|
                    if k==:default then
                        v.map {|x| x.call}.join("\n")
                    else
                        v.call
                    end
                end.filter do |x| x!="" end
    
                # puts _opal_before_code_lazy
                # puts _opal_before_code
                # puts _opal_after_code
                # puts _opal_after_code_lazy

                
                to_opal_compile = _opal_before_code_lazy + _opal_before_code+@opal+_opal_after_code + _opal_after_code_lazy
                
                # puts to_opal_compile

                if @opal.size > 0 then
                    @opal_compile = @opal_compile + @opal_require.map do |opal_req|
                        Opal::Builder.new.build_str("require '#{opal_req}'","")                
                    end
                    @opal_compile = @opal_compile + to_opal_compile.map do |opal|
                        Opal::Builder.new.build_str(opal,"")                
                    end
                end

                <<~HTML
                <html>
                    <head>
                    #{@head.join("\n")}
                    </head>
                    <body>
                    #{@body.join("\n")}
                    #{(@js+@opal_compile).map do |jscode| 
                        <<~JSCODE
                            <script type="application/javascript">
                                #{jscode}
                            </script>
                        JSCODE
                    end.join("\n")}
                    </body>
                </html>
                HTML
            end

            def open_browser(file)

                @file = File.expand_path(file)

                ## auto-refresh feature for development
                self.js(<<~JSCODE
                    globalThis.__render_timestamp = #{File.mtime(@file).to_i}

                    setInterval(function () {
                        const xhttp = new XMLHttpRequest();
                        xhttp.onload = function() {
                            if (this.responseText-globalThis.__render_timestamp>0) {
                                location.reload();
                            }
                        }
                        xhttp.onerror = function() { };
                        xhttp.open("GET", "/render_timestamp");
                        xhttp.send();                        
                    }, 1000);

                    JSCODE
                )

                @@last_render = self

                # puts "@@first_render = #{@@first_render}"
                # puts "@@last_render = #{@@last_render}"
                # puts "@@server = #{@@server}"

                if @@server == nil then


                    status = system "open http://localhost:8080/render"
                    raise "cannot launch a web browser" if status.nil?
        
                    @@server = WEBrick::HTTPServer.new(
                        :BindAddress => '0.0.0.0',
                        :Port => 8080,
                        :AccessLog => []
                    )

                    @@server.mount_proc('/render_timestamp') do |req, res|
                        peer_address  = req.peeraddr[3]
                        if peer_address != '127.0.0.1'
                            $stderr.puts "access denied address=#{peer_address}"
                            raise WEBrick::HTTPStatus::Forbidden
                        end

                        # puts "http mtime = #{File.mtime(@file).to_i.to_s}"

                        res.body = File.mtime(@file).to_i.to_s
                    end            
                        
        
                    @@server.mount_proc('/render') do |req, res|

                        peer_address  = req.peeraddr[3]
                        if peer_address != '127.0.0.1'
                            $stderr.puts "access denied address=#{peer_address}"
                            raise WEBrick::HTTPStatus::Forbidden
                        end
                        
                        if @@first_render then
                            SmartBook::Widget::VarBinding.global = {}
                            load(@file)
                        else
                            @@first_render = self
                        end

                        res.body = @@last_render.output
                    end            
        
                    trap 'INT' do @@server.shutdown end
                    @@server.start                
                end
            end
        end

    end

end


