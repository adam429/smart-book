require 'webrick'

module Render

    class Render       
        @@server = nil 
        @@first_render = nil
        @@last_render = nil

        attr_accessor :body, :head, :js, :opal, :file

        def initialize
            @body = []
            @head = []
            @js = []
            @opal = []
        end

        def body(html)
            @body.push(html)
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

        def output
            <<~HTML
            <html>
                <head>
                #{@head.join("\n")}
                </head>
                <body>
                #{@body.join("\n")}
                #{@js.map do |jscode| 
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
            @file = file

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

                    res.body = File.mtime(@file).to_i.to_s
                end            
                    
    
                @@server.mount_proc('/render') do |req, res|
                    peer_address  = req.peeraddr[3]
                    if peer_address != '127.0.0.1'
                        $stderr.puts "access denied address=#{peer_address}"
                        raise WEBrick::HTTPStatus::Forbidden
                    end
                    
                    load(@file)

                    res.body = @@last_render.output
                end            
    
                trap 'INT' do @@server.shutdown end
                @@server.start                
            end
        end
    end

end