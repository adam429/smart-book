require 'smartbook/thread_wait'

require 'smartbook/source_code'
require 'smartbook/persistence'
require 'smartbook/render'
require 'smartbook/widget'

require 'smartbook/require_remote'

require 'smartbook/file_cache'
require 'smartbook/lazyexec'

require 'smartbook/web3'


module SmartBook
    VERSION = 0.1

    def load_dotenv_recursive
        dir = __dir__
        while not File.exist?(dir + "/.env") do
          dir = dir.split("/")
          dir.pop
          dir = dir.join("/")
          return if dir == "/" || dir == "" || dir == "."
        end
        Dotenv.load(dir + "/.env") 
    end      
end
