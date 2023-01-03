require 'webrick'
require 'erb'
require 'opal'
require 'opal-browser'
require 'method_source'

module SmartBook

    module Render

        class Render       
            @@server = nil 
            @@first_render = nil
            @@last_render = nil
            # @@req = nil

            attr_accessor :body, :head, :js, :opal, :opal_require, :file

            def initialize
                @body = []
                @head = []
                @js = []
                @opal = []
                @opal_require = ["opal","promise","native","browser"]
            end

            class VarBinding
                def initialize(vars)
                    vars.each do |k,v|
                        instance_variable_set("@#{k}", v)
                    end
                end
                def get_binding
                  binding
                end
            end

            def body(html,vars={})                
                @body.push(ERB.new(html).result(VarBinding.new(vars).get_binding))
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

            def opal_load_code(symbol)
                begin
                    opal(MethodSource::source_helper(Object.const_source_location(symbol)))
                rescue 
                end
                begin
                    opal(method(symbol).source)
                rescue 
                end
            end

            def opal_require(opal_req)
                @opal_require.push(opal_req)
            end

            def output
                @opal_compile = []

                if @opal.size > 0 then
                    @opal_compile = @opal_compile + @opal_require.map do |opal_req|
                        Opal::Builder.new.build_str("require '#{opal_req}'","")                
                    end
                    @opal_compile = @opal_compile + @opal.map do |opal|
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
                    @@first_render = self


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
                        
                        # puts "@file =#{@file}"
                        load(@file)

                        res.body = @@last_render.output
                    end            
        
                    trap 'INT' do @@server.shutdown end
                    @@server.start                
                end
            end
        end

    end

end