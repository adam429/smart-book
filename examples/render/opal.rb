require 'smartbook'

src = <<~HTML
    <h1>Hello World</h1>
    <p>Current time: <span id="time">#{Time.now}</span></p>
    <p> <a id="button" href="#"> click me </a></p>
    <p> counter: <span id="counter">0</span></p>
HTML

opal1 = <<~OPAL
    puts "hello world!"
OPAL

opal2 = <<~OPAL
    puts "welcome"
OPAL

render = SmartBook::Render::Render.new

render.body(src)

render.opal(opal1)
render.opal(opal2)

render.open_browser(__FILE__)

