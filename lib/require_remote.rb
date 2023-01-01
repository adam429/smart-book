require 'uri'
require 'net/http'
require 'fileutils'
require 'parser/current'
require 'unparser'
require 'thread/pool'

Parser::Builders::Default.emit_lambda              = true
Parser::Builders::Default.emit_procarg0            = true
Parser::Builders::Default.emit_encoding            = true
Parser::Builders::Default.emit_index               = true
Parser::Builders::Default.emit_arg_inside_procarg0 = true
Parser::Builders::Default.emit_forward_arg         = true
Parser::Builders::Default.emit_kwargs              = true
Parser::Builders::Default.emit_match_pattern       = true

module RequireRemote
    THREAD_POOL = 10
    BRANCH = 'main'
    CACHE_DIR = ".remote_cache"

    def require_remote(uri)
        # require file from https://raw.githubusercontent.com/adam429/smart-book/main/examples/require_remote/lib/math_lib.rb
        # require_remote '@adam429/smart-book/examples/require_remote/lib/math_lib'

        rr = RequireRemote.new(uri)
        rr.parse_uri()
        rr.add_load_path
        require rr.local_require
    end

    class RequireRemoteError < StandardError
    end

    class RequireRemoteURIError < RequireRemoteError
    end

    class SourceCode
        attr_accessor :uri, :user, :file, :ext, :repo, :dir, :base_dir, :url, :code, :include_uri

        def initialize(uri)
            @include_uri = []
            parse_uri(uri)
        end

        def parse_uri(uri)
            @uri = uri[:uri]
            @base_dir = uri[:base_dir]
            
            sectors = @uri.split("@")

            raise RequireRemoteURIError if sectors.size!=2
            raise RequireRemoteURIError if sectors[0]!=""
            
            sector = (sectors[1]).split("/")

            @user = sector[0]
            @file = sector[-1] 
            @ext = ".rb"
            @repo = sector[1]
            @dir = sector[2,sector.size-3].join("/")
            @base_dir = @dir if @base_dir==nil
            
            @url = ['https://raw.githubusercontent.com', @user,@repo,BRANCH,@dir,@file+@ext].join("/")

            @code = _get_remote_files(@url)
            _save_to_cache(CACHE_DIR,[@repo,@dir].join("/"),@file+@ext,@code)

            _parse_code(@code);
        end

        def _get_remote_files(uri)
            Net::HTTP.get_response(URI(uri)).body
        end

        def _save_to_cache(cache,path,filename,code)
            FileUtils.mkdir_p [cache,path].join("/")
            open([cache,path,filename].join("/"),"w") do |file|
                file.write(code);
            end
        end

        def _parse_code(code)
            root = Parser::CurrentRuby.parse(code)
            _parse_node(root)
        end

        def _parse_node(node)
            if node.type==:send and node.children[1]==:require then
                file = eval(Unparser.unparse(node.children[2]))

                sector = ["@"+@user,@repo,@base_dir,file]
                
                @include_uri.push({:uri=>sector.join("/"),:base_dir=>@base_dir})
            end

            if node.type==:send and node.children[1]==:require_relative then
                file = eval(Unparser.unparse(node.children[2]))
                
                ## remove "./" head if exist
                file.gsub!(/^\.\//,"")
                subdir = @dir.gsub(/#{@base_dir}/,"")

                subdir.gsub!(/^\//,"")
                subdir = subdir + "/" if subdir!=""
                file =  subdir + file

                sector = ["@"+@user,@repo,@base_dir,file]
                
                @include_uri.push({:uri=>sector.join("/"),:base_dir=>@base_dir})
            end
            
            node.children.each do |child|
                _parse_node(child) if child.class ==Parser::AST::Node
            end
        end
    end

    class RequireRemote
        attr_accessor :source, :uri_list, :pool

        def initialize(uri)
            @source = []
            @uri_list = [{:uri=>uri,:base_dir=>nil}]
        end

        def parse_uri()
            @pool = Thread.pool(THREAD_POOL)            
            _new_thread(@uri_list.shift)
            @pool.wait(:done)
            @pool.shutdown
        end

        def _new_thread(uri)
            @pool.process do
                # puts "Thread ID #{Thread.current.object_id} - Begin at #{Time.now}"
                # puts "Thread ID #{Thread.current.object_id} - URI = #{uri[:uri]}"
                code = SourceCode.new(uri)
                @source.push(code)
                code.include_uri.each do |uri|
                    _new_thread(uri)
                end
                # puts "Thread ID #{Thread.current.object_id} - End at #{Time.now}"
            end
        end

        def local_require()
            return @source.first.file
        end

        def add_load_path()
            libdir = "./" + [CACHE_DIR,@source.first.repo,@source.first.dir].join("/")
            $LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
        end
    end
end

include RequireRemote



