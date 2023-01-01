def require_remote(path)
    puts path
end

# fetch file to tmp dir, and require
# cache to avoid repeat download
# recurse ast parse to find more load / require / require_relative / etc...