# load library remotely by require_remote
require 'require_remote'

# require file from https://raw.githubusercontent.com/adam429/smart-book/main/examples/require_remote/lib/math_lib.rb
require_remote '@adam429/smart-book/examples/require_remote/lib/math_lib'

puts MathLib::PI
puts MathLib.sum(1, 2)
