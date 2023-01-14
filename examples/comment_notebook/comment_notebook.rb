require 'smartbook'

# normal code
puts "welcome to inline comment notebook"


# @notebook notebook
"hello world"
# @result
# > "hello world"

a=1
b=2
def sum(a,b)
  a+b
end

# @notebook
sum(a+b)
# @result
# > 3



# @notebook
"<span></span>"
# @result
# open http://localhost:4567/1
# > "<span></span>"

