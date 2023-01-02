require 'render'

src = <<~HTML
   <h1>Hello World</h1>
   <% 10.times do |x| %>
      <li><%= x %></li>
   <% end %>
HTML

render = Render::Render.new
render.body(src)
render.open_browser
