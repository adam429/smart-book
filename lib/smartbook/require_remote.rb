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

module SmartBook

    module RequireRemote

        class GithubRemote
            @@base_dir = nil

            attr_accessor :uri, :user, :file, :ext, :repo, :dir, :url

            def self.match(remote_uri)
                return true if remote_uri[0] == "@"
                
                return false
            end

            def base_dir
                @@base_dir
            end

            def initialize()
                @branch = "main"
                @github_url = "https://raw.githubusercontent.com"
            end

            def parse_uri(uri)
                @uri = uri
                sectors = @uri.split("@")

                raise RequireRemoteURIError.new if sectors.size!=2
                raise RequireRemoteURIError.new if sectors[0]!=""
                
                sector = (sectors[1]).split("/")
                @user = sector[0]
                @file = sector[-1] 
                @ext = ".rb"
                @repo = sector[1]
                @dir = sector[2,sector.size-3].join("/")
                @@base_dir = @dir if @@base_dir==nil
                
                @url = [@github_url, @user,@repo,@branch,@dir,@file+@ext].join("/")
            end

            def path
                return [@repo,@dir].join("/")
            end

            def filename
                return @file+@ext
            end
        end

        class CacheLocal
            attr_accessor :local_filename, :local_file, :local_dir

            def initialize(parser)
                @parser = parser                
            end

            def save(code)
                cache = CONFIG[:CACHE_DIR] or ".remote_cache"
                
                path = @parser.path
                filename = @parser.filename

                FileUtils.mkdir_p [cache,path].join("/")

                @local_filename = [cache,path,filename].join("/")
                open(@local_filename,"w") do |file|
                    file.write(code);
                end

                @local_file = filename.split(".").first
                @local_dir = [cache,path].join("/")
            end
        end

        class RequireRemoteError < StandardError
        end

        class RequireRemoteParserError < RequireRemoteError
        end

        class RequireRemoteURIError < RequireRemoteError
        end

        class SourceCode
            attr_accessor :include_uri, :parser, :url

            def initialize(uri)
                @include_uri = []
                _parse_uri(uri)
            end

            def local_file
                @local_saver.local_file
            end

            def local_dir
                @local_saver.local_dir
            end

            def _parse_uri(uri)
                match_parser = CONFIG[:REMOTE_PARSER].filter do |x|
                    x.match(uri)
                end

                if match_parser.size > 0 then
                    @parser = (match_parser.first).new
                else
                    raise RequireRemoteParserError.new
                end

                @parser.parse_uri(uri)
                @code = _get_remote_files(@parser.url)

                @local_saver = CONFIG[:LOCAL_SAVER].new(@parser)
                @local_saver.save(@code)
    
                _parse_code(@code);
            end

            def _get_remote_files(uri)
                ret = Net::HTTP.get_response(URI(uri)).body
                # puts "== #{uri} =="
                # puts ret
                return ret
            end


            def _parse_code(code)
                root = Parser::CurrentRuby.parse(code)
                _parse_node(root)
            end

            def _parse_node(node)
                if node.type==:send and node.children[1]==:require then
                    file = eval(Unparser.unparse(node.children[2]))

                    sector = ["@"+@parser.user,@parser.repo,@parser.base_dir,file]
                    
                    @include_uri.push(sector.join("/"))
                end

                if node.type==:send and node.children[1]==:require_relative then
                    file = eval(Unparser.unparse(node.children[2]))
                    
                    ## remove "./" head if exist
                    file.gsub!(/^\.\//,"")
                    subdir = @parser.dir.gsub(/#{@parser.base_dir}/,"")

                    subdir.gsub!(/^\//,"")
                    subdir = subdir + "/" if subdir!=""
                    file =  subdir + file

                    sector = ["@"+@parser.user,@parser.repo,@parser.base_dir,file]
                    
                    @include_uri.push(sector.join("/"))
                end
                
                node.children.each do |child|
                    _parse_node(child) if child.class ==Parser::AST::Node
                end
            end
        end

        class RequireRemote
            attr_accessor :source, :uri_list, :pool

            def initialize(remote_uri)
                @source = []
                @uri_list = [remote_uri]
                _parse_remote_uri()
            end

            def _parse_remote_uri()
                Thread::Pool.abort_on_exception=true

                @pool = Thread.pool(CONFIG[:THREAD_POOL])
                    
                _fetch_code(@uri_list.shift)

                @pool.wait(:done)
                @pool.shutdown
            end

            def _new_thread() 
                if CONFIG[:THREAD_POOL]>1 then
                    @pool.process do
                        yield
                    end
                else
                    yield
                end
            end

            def _fetch_code(uri)
                _new_thread() do
                    # puts "Thread ID #{Thread.current.object_id} - Begin at #{Time.now}"
                    # puts "Thread ID #{Thread.current.object_id} - URI = #{uri}"
                    code = SourceCode.new(uri)
                    @source.push(code)
                    code.include_uri.each do |uri|
                        _fetch_code(uri)
                    end
                    # puts "Thread ID #{Thread.current.object_id} - End at #{Time.now}"
                end

            end

            def local_require()
                return @source.first.local_file
            end

            def add_load_path()
                libdir = "./" + @source.first.local_dir

                $LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
            end
        end

        CONFIG = {
            :THREAD_POOL => 1,
            :CACHE_DIR => ".remote_cache",
            :REMOTE_PARSER => [GithubRemote],
            :LOCAL_SAVER => CacheLocal
        }

        def require_remote(remote_uri)
            # require file from https://raw.githubusercontent.com/adam429/smart-book/main/examples/require_remote/lib/math_lib.rb
            # require_remote '@adam429/smart-book/examples/require_remote/lib/math_lib'
            rr = RequireRemote.new(remote_uri)
            rr.add_load_path
            require rr.local_require
        end

    end
end

include SmartBook::RequireRemote



