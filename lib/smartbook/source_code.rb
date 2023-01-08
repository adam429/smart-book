require 'method_source'

module SmartBook
    module SourceCode
        def self._generate_mod(mod,code)
            return code if mod==""

            code = code + "\n"

            mod.split("::").reverse.each do |x|
                code = "module #{x}\n" + code + "end\n"
            end

            return code 
        end

        def self.source_code(obj)
            begin
                # try class/module
                mod = Object.const_get(obj.to_s).name.split("::")
                mod.pop
                mod = mod.join("::")
                code = MethodSource::source_helper(Object.const_source_location(obj.to_s))
                return self._generate_mod(mod,code)
            rescue 
            end

            begin
                # try method
                mod = ""
                if obj.to_s !=~ /::/ then
                    mod = method(obj.to_s).owner.to_s
                    mod = "" if mod=="Object"
                end
                code = MethodSource::source_helper(method(obj.to_s).source_location)

                return self._generate_mod(mod,code)
            rescue 
            end

            begin
                # try class method and instance method definfed in class 
                split = obj.to_s.split(".")
                if split.size==2 then
                    mod = split[0].split("::")
                    mod.pop
                    mod = mod.join("::")

                    begin
                       return self._generate_mod(mod,Object.const_get(split[0]).method(split[1]).source)
                    rescue 
                    end
                    begin
                       return self._generate_mod(mod,Object.const_get(split[0]).instance_method(split[1]).source)
                    rescue 
                    end
                end
            rescue
            end

            begin
                # try module method and instance method definfed in class 
                split = obj.to_s.split("::")

                name = split.pop
                mod = split.join("::")
                
                begin
                    return self._generate_mod(mod,Object.const_get(mod).method(name).source)
                rescue 
                end
                begin
                    return self._generate_mod(mod,Object.const_get(mod).instance_method(name).source)
                rescue 
                end
            rescue
            end

            return ""
        end
    end
end

class Symbol
    def source_code
        SmartBook::SourceCode.source_code(self)
    end
end     

class Class
    def source_code
        SmartBook::SourceCode.source_code(self.name)
    end
end

class Module
    def source_code
        SmartBook::SourceCode.source_code(self.name)
    end
end