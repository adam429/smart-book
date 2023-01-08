require 'smartbook/render'
require 'smartbook/persistence'
require 'json'

module SmartBook

    module Widget

        class VarBinding < Persistence
            @@global = {}

            def self.global
                @@global
            end    

            def self.[]=(key,val)
                self.global[key] = val
            end
            
            def self.[](key)
                self.global[key]
            end
                        

            def to_json(*args)
                {
                    JSON.create_id  => self.class.name,
                    :data           => @@global
                }.to_json(*args)
            end           
            
            def self.json_create(object)
                @@global = self.symbolize_names(object)[:data]
                self.new
            end            

        end 


        class Widget
            @@wid = 1

            attr_accessor :val, :style, :wid

            def to_html
                return ""
            end
            
            def initialize
                @wid = @@wid
                @@wid = @@wid + 1

                @style = {}
                @val = nil
            end
        end

        class Text < Widget
            def to_html
                return "<span id='#{wid}' style='#{style.map{|k,v| "#{k}:#{v}"}.join(";")}'>#{val}</span>"
            end
        end

        module Helper
            def def_var(key,value)
                VarBinding.global[:var_table] = {} unless VarBinding.global[:def_var_table]
                VarBinding.global[:var_table][key] = value            

            end
            
            def text(val,style={})
                widget = Text.new
                widget.val = val
                widget.style = style
                widget.to_html 
            end
        end

    end
end

SmartBook::Render::Binding.include(SmartBook::Widget::Helper)