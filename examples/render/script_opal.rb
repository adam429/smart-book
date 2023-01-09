require 'smartbook'

src = <<~HTML
    <p>Current time: <span id="time">#{Time.now}</span></p>
    <p> <a id="button" href="#"> click me </a></p>
    <p> counter: <span id="counter">0</span></p>
HTML

opal1 = <<~OPAL
    puts "hello world!"
OPAL

opal2 = <<~OPAL
    i = 0

    $document.at_css("#time")["style"] = $document.at_css("#time")["style"].to_s + ";color:red"

    $document.at_css("#button").on(:click) do
        i = i+1
        $document.at_css("#counter").inner_text = i
    end
OPAL

render = SmartBook::Render::Render.new

render.body(src)

render.opal(opal1)
render.opal(opal2)

render.open_browser(__FILE__)

