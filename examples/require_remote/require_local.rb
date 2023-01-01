# load library locally by require

libdir = File.expand_path(File.dirname(__FILE__)) + "/lib"
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'math_lib'

puts MathLib::PI
puts MathLib.sum(1, 2)
