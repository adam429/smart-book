require "minitest/autorun"
require 'smartbook/source_code'

def sum(a,b)
  return a+b
end

$code_sum = <<~RUBY
def sum(a,b)
  return a+b
end
RUBY


class MathLib
  def mul(a,b)
    return a*b
  end
  def self.pi
    3.1415
  end
end

$code_mathlib = <<~RUBY
class MathLib
  def mul(a,b)
    return a*b
  end
  def self.pi
    3.1415
  end
end
RUBY

$code_mathlib_mul = <<-RUBY
  def mul(a,b)
    return a*b
  end
RUBY

$code_mathlib_pi = <<-RUBY
  def self.pi
    3.1415
  end
RUBY


module Mod1
module Mod2
  class Klass
  end
  def add(a,b)
    a+b
  end
  def self.sub(a,b)
    a-b
  end
end
end

$code_mod = <<~RUBY
module Mod1
module Mod2
  class Klass
  end
  def add(a,b)
    a+b
  end
  def self.sub(a,b)
    a-b
  end
end
end
RUBY

$code_mod_klass = <<-RUBY
module Mod1
module Mod2
  class Klass
  end

end
end
RUBY

$code_mod_add = <<-RUBY
module Mod1
module Mod2
  def add(a,b)
    a+b
  end

end
end
RUBY

$code_mod_sub = <<-RUBY
module Mod1
module Mod2
  def self.sub(a,b)
    a-b
  end

end
end
RUBY

include Mod1::Mod2


class TestSoureCode < Minitest::Test
  def output(obj)
    puts "-----"
    puts SmartBook::SourceCode.source_code(obj).gsub(/\n/,"\\n")
    puts "-----"
  end

  def test_method
    assert SmartBook::SourceCode.source_code("sum")==$code_sum
    assert SmartBook::SourceCode.source_code(:sum)==$code_sum
    assert :sum.source_code == $code_sum
  end

  def test_module
    assert SmartBook::SourceCode.source_code("Mod1")==$code_mod
    assert SmartBook::SourceCode.source_code(:Mod1)==$code_mod
    assert :Mod1.source_code == $code_mod
    assert Mod1.source_code == $code_mod

    assert SmartBook::SourceCode.source_code("Mod1::Mod2::Klass")==$code_mod_klass
    assert SmartBook::SourceCode.source_code(:"Mod1::Mod2::Klass")==$code_mod_klass
    assert :"Mod1::Mod2::Klass".source_code == $code_mod_klass
    assert Mod1::Mod2::Klass.source_code == $code_mod_klass

    # output("Mod1::Mod2::sub")
    # puts $code_mod_sub.gsub(/\n/,"\\n")

    assert SmartBook::SourceCode.source_code("Mod1::Mod2::sub")==$code_mod_sub
    assert SmartBook::SourceCode.source_code(:"Mod1::Mod2::sub")==$code_mod_sub
    assert :"Mod1::Mod2::sub".source_code == $code_mod_sub

    assert SmartBook::SourceCode.source_code("Mod1::Mod2::add")==$code_mod_add
    assert SmartBook::SourceCode.source_code(:"Mod1::Mod2::add")==$code_mod_add
    assert :"Mod1::Mod2::add".source_code == $code_mod_add

  end

  def test_class
    assert SmartBook::SourceCode.source_code("MathLib")==$code_mathlib
    assert SmartBook::SourceCode.source_code(:MathLib)==$code_mathlib
    assert :MathLib.source_code == $code_mathlib
    assert MathLib.source_code == $code_mathlib

    assert SmartBook::SourceCode.source_code("MathLib.mul")==$code_mathlib_mul
    assert SmartBook::SourceCode.source_code(:"MathLib.mul")==$code_mathlib_mul
    assert :"MathLib.mul".source_code == $code_mathlib_mul

    assert SmartBook::SourceCode.source_code("MathLib.pi")==$code_mathlib_pi
    assert SmartBook::SourceCode.source_code(:"MathLib.pi")==$code_mathlib_pi
    assert :"MathLib.pi".source_code == $code_mathlib_pi
  
  end

  def test_include
    assert SmartBook::SourceCode.source_code("Klass")==$code_mod_klass
    assert SmartBook::SourceCode.source_code(:"Klass")==$code_mod_klass
    assert :"Klass".source_code == $code_mod_klass
    assert Klass.source_code == $code_mod_klass

    assert SmartBook::SourceCode.source_code("add")==$code_mod_add
    assert SmartBook::SourceCode.source_code(:"add")==$code_mod_add
    assert :"add".source_code == $code_mod_add
  end

end