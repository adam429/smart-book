require 'render'

src = <<~HTML
    <h1>Hello World</h1>
    <p>Current time: <span id="time">#{Time.now}</span></p>
    <p> <a id="button" href="#"> click me </a></p>
    <p> counter: <span id="counter">0</span></p>
HTML

render = Render::Render.new

render.body(src)

render.opal()

render.open_browser(__FILE__)
