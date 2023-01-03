require 'smartbook'

src = <<~HTML
    <p>Current time: <span id="time">#{Time.now}</span></p>
    <p> <a id="button" href="#"> click me </a></p>
    <p> counter: <span id="counter">0</span></p>
HTML

js1 = <<~JSCODE
console.log("hello world!");
JSCODE

js2 = <<~JSCODE
document.getElementById("time").style.color = "red";

i=0;

$( "#button" ).on( "click", function( event ) {
    i=i+1;
    $( "#counter" ).html(i);
});    
JSCODE


render = SmartBook::Render::Render.new

render.head(<<~JSCODE
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.3/jquery.min.js" integrity="sha512-STof4xm1wgkfm7heWqFJVn58Hm3EtS31XFaagaa8VMReCXAkQnJZ+jEy8PCC/iT18dFy95WcExNHFTqLyp72eQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
JSCODE
)

render.body(src)
render.js(js1)
render.js(js2)
render.open_browser(__FILE__)
