require 'smartbook'

src = <<~HTML
    <p> a: <span id="a"></span>   b: <span id="b"></span></p>
    <p> sum: <span id="sum"></span></p>
    <p> mul: <span id="mul"></span></p>
HTML

opal = <<~OPAL
    a = 3
    b = 4
    $document.at_css("#a").inner_html = a
    $document.at_css("#b").inner_html = b
    $document.at_css("#sum").inner_html = sum(a,b)
    $document.at_css("#mul").inner_html = MathLib.mul(a,b)
OPAL

def sum(a,b)
    a+b
end

class MathLib
    def self.mul(a,b)
        a*b
    end
end

render = SmartBook::Render::Render.new

render.body(src)

render.opal_load_code(:sum)
render.opal_load_code(:MathLib)
render.opal(opal)

render.open_browser(__FILE__)

