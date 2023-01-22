require 'dotenv'

module SmartBook
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
