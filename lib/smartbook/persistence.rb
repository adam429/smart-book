require 'smartbook/source_code'
require 'json'

module SmartBook

    class Persistence         
        @@import_class = []

        def add_import(obj)
            klass_tree = []
            klass = obj.class

            while klass!=Object do
                klass_tree.push(klass)
                klass = klass.superclass
            end
            @@import_class = @@import_class + klass_tree.reverse
        end

        def self.serialize(obj)
            obj.to_json
        end

        def self.unserialize(data)
            self.symbolize_names(JSON.load(data, {create_additions: true}))
        end

        def self.symbolize_names(data)
            if data.class == Hash then
                return data.map {|k,v| [k.to_sym,self.symbolize_names(v)]}.to_h
            end

            if data.class == Array then
                return data.map {|v| self.symbolize_names(v)}
            end

            return data
        end

        def self.to_opal(obj,opal_name = "_")
            @@import_class = [Persistence]

                # {Persistence.source_code}
                # {obj.class.source_code }

            ret = <<~OPAL
                #{obj.class.to_s.split("::").last.downcase}_to_opal = <<~TO_OPAL_DATA
                    #{Persistence.serialize(obj)}
                TO_OPAL_DATA
                #{opal_name} = SmartBook::Persistence.unserialize(#{obj.class.to_s.split("::").last.downcase}_to_opal)
            OPAL

            ret = @@import_class.uniq.map {|x| x.source_code}.join("\n") + ret 

            return ret
        end    
    end

end