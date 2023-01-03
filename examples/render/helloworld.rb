require 'render'

src = <<~HTML
   <h1>Hello World</h1>
   <p>Current time: <span id="time">#{Time.now}</span></p>
HTML

render = Render::Render.new
render.body(src)
render.open_browser
