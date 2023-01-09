# todo

require 'smartbook'

src = <<~HTML
    <h1>Widgets and Binding</h1>
    <p> <a id="btn_red" href="#"> red </a> <a id="btn_green" href="#"> green </a></p>
    <p> <a id="btn_small" href="#"> small </a> <a id="btn_mid" href="#"> mid </a> <a id="btn_big" href="#"> big </a></p>

    
    <%= text("hello world!",{:color=>"red"}) %> <br/>
    <%= text(:text,{:color=>:color,:"font-size"=>:"font-size"}) %>

    <% def_var(:text,"hello world!") %>
    <% def_var(:color,"red") %>
    <% def_var(:"font-size","12") %>

    <br/>
HTML



    # <% def_calc_var(:text,%( "the color is" + :color )) %>


opal = <<~OPAL
    puts SmartBook::Widget::VarBinding.global

    $document.at_css("#btn_red").on(:click) do
        SmartBook::Widget::VarBinding.set_var(:color,"red")
        SmartBook::Widget::VarBinding.set_var(:text,"red")
    end

    $document.at_css("#btn_green").on(:click) do
        SmartBook::Widget::VarBinding.set_var(:color,"green")
        SmartBook::Widget::VarBinding.set_var(:text,"green")
    end

    $document.at_css("#btn_small").on(:click) do
        SmartBook::Widget::VarBinding.set_var(:"font-size","12")
    end

    $document.at_css("#btn_mid").on(:click) do
        SmartBook::Widget::VarBinding.set_var(:"font-size","24")
    end

    $document.at_css("#btn_big").on(:click) do
        SmartBook::Widget::VarBinding.set_var(:"font-size","36")
    end
OPAL

render = SmartBook::Render::Render.new

render.body(src)
render.opal(opal)
# render.output
render.open_browser(__FILE__)

