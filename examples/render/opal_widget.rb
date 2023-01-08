# todo

require 'smartbook'

src = <<~HTML
    <h1>Widgets and Binding</h1>
    <%= text("hello world!",{:color=>"red"}) %>
    
    <% def_var(:text,"hello world!") %>
    <% def_var(:color,"red") %>

    <br/>

    <%= text(:text,{:color=>:color}) %>
HTML



opal = <<~OPAL
OPAL

render = SmartBook::Render::Render.new

render.body(src)
render.opal(opal)
render.open_browser(__FILE__)


puts $global_code