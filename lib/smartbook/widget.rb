require 'smartbook/render'
require 'smartbook/persistence'
require 'json'

module SmartBook

    module Widget

        class VarBinding < Persistence
            @@global = {}

            class << self
                attr_accessor :render
            end

            def self.global
                @@global
            end    
            def self.global=(val)
                @@global = val
            end    


            def global
                @@global
            end

            def self.[]=(key,val)
                self.global[key] = val
            end
            
            def self.[](key)
                self.global[key]
            end
                        
            def to_json(*args)
                self.add_import(self)
                {
                    JSON.create_id  => self.class.name,
                    :data           => @@global
                }.to_json(*args)
            end           
            
            def self.json_create(object)
                @@global = self.symbolize_names(object)[:data]
                self.new
            end            

            def self.def_var(key,value="(binding)",override=true)
                # puts "def_var #{key} #{value} #{override}"
                VarBinding.global[:var_table] = {} unless VarBinding.global[:var_table]

                if override or not VarBinding.global[:var_table].has_key?(key) then
                    VarBinding.global[:var_table][key] = value            
                end

                render.add_opal_before_code_lazy(:def_var) do
                    "require 'json'\n"+
                    SmartBook::Persistence.to_opal(VarBinding.new)
                end
            end                

            # run in ruby, to generate opal code
            def self.binding(widget, writer, value)
                # puts "binding #{widget.id} #{writer} #{value}"
                if value.class == String then
                    ret = value
                end

                if value.class == Symbol then
                    VarBinding.global[:var_binding] = {} unless VarBinding.global[:var_binding]

                    VarBinding.global[:var_binding][value] = { id: widget.id, writer: writer }
                    
                    VarBinding.def_var(value,"(binding)",false)
                    ret = "(binding)"

                    code = <<~OPAL
                        SmartBook::Widget::VarBinding.update(:#{value})
                    OPAL
                    widget.render.add_opal_after_code(code)                                     
                end

                if value.class == Hash then
                    
                    val_name = []
                    VarBinding.global[:var_binding] = {} unless VarBinding.global[:var_binding]

                    ret = value.map do |k,v|
                        if v.class == Symbol then
                            val_name.push(v)
                            VarBinding.global[:var_binding][v] = { id: widget.id, writer: writer, hash_key: k }
                            VarBinding.def_var(v,"(binding)",false)
                            [k, "(binding)"]
                        else
                            [k,v]
                        end
                    end.to_h

                    code = val_name.map do |vn| 
                        "SmartBook::Widget::VarBinding.update(:#{vn})"
                    end.join("\n")
                    widget.render.add_opal_after_code(code)                                     

                end

                return ret
            end

            # run in opal, to set the var
            def self.set_var(val_name, value)
                VarBinding.global[:var_table] = {} unless VarBinding.global[:var_table]
                VarBinding.global[:var_table][val_name] = value
                VarBinding.update(val_name)
            end

            # run in opal, to update the dom
            def self.update(val_name)
                value = VarBinding.global[:var_table][val_name]
                var_binding = VarBinding.global[:var_binding][val_name]

                if var_binding[:writer] == :inner_text then
                    $document.at_css("##{var_binding[:id]}").inner_text = value
                end
                if var_binding[:writer] == :style then
                    # puts "update #{val_name} #{value} #{var_binding}"
                    style = $document.at_css("##{var_binding[:id]}")[:style]
                    style = style.split(";").map {|x| x.split(":")}.to_h
                    style[var_binding[:hash_key]] = value
                    style = style.map{|k,v| "#{k}:#{v}"}.join(";")
                    $document.at_css("##{var_binding[:id]}")[:style] = style
                end

            end

        end 


        class Widget
            @@id = 1
            attr_accessor :id, :render
            attr_reader :style

            def style=(val)
                @style = VarBinding.binding(self, :style, val)
            end

            def to_html
                return ""
            end
            
            def initialize
                @id = "widget-#{@@id}"
                @@id = @@id + 1

                @style = {}
                @val = nil
            end

            def style_str
                @style.map{|k,v| "#{k}:#{v}"}.join(";")
            end
        end

        class Text < Widget
            attr_reader :inner_text

            def inner_text=(val)    
                @inner_text = VarBinding.binding(self, :inner_text, val)
            end

            def to_html
                return "<span id='#{id}' style='#{style_str}'>#{inner_text}</span>"
            end
        end

        module Helper
            def def_var(key,value)
                VarBinding.render = get_render
                VarBinding.def_var(key,value)
                return ""
            end
            
            def text(inner_text,style={})
                VarBinding.render = get_render

                widget = Text.new
                widget.render = get_render
                widget.inner_text = inner_text
                widget.style = style
                                
                return widget.to_html            
            end
        end

    end
end

SmartBook::Render::Binding.include(SmartBook::Widget::Helper)