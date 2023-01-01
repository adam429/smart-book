# load library remotely by require_remote

require 'require_remote'

# https://www.github.com/adam429/smart-book
require_remote '@adam429/smart-book/examples/require_remote/lib/math_lib'

puts MathLib::PI
puts MathLib.sum(1, 2)
puts MathLib.abs(-10)