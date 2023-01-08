# todo

require 'smartbook'

src = <<~HTML
    <h1>Load Code into Browser</h1>

    <pre>@adam429/smart-book/examples/require_remote/lib/math_lib</pre>

    <h1>Run Code in Browser</h1>
    <p> a: <span id="a"></span>   b: <span id="b"></span></p>
    <p> sum: <span id="sum"></span></p>
    <p> mul: <span id="mul"></span></p>
HTML

opal = <<~OPAL
    a = 3
    b = 4
    $document.at_css("#a").inner_html = a
    $document.at_css("#b").inner_html = b
    $document.at_css("#sum").inner_html = MathLib.sum(a,b)
    $document.at_css("#mul").inner_html = MathLib.mul(a,b)
OPAL

render = SmartBook::Render::Render.new

render.body(src)

render.opal_load_code("@adam429/smart-book/examples/require_remote/lib/math_lib")
render.opal(opal)

render.open_browser(__FILE__)

