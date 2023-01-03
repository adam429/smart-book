require 'smartbook'


src = <<~HTML
   <h1>Hello World</h1>
   <p>foo = <%= @foo %></p>
   <p>bar = <%= @bar %></p>
   <p>sum = <%= sum(1,2) %></p>
   <% 10.times do |x| %>
    <li><%= x %></li>
 <% end %>
HTML

def sum(a,b)
   a+b
end

render = SmartBook::Render::Render.new
render.body(src,{:foo=>"foo", :bar=>"bar"})
render.open_browser(__FILE__)
