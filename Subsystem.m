classdef Subsystem
    properties
        handle
        model_name
        model_path
        interface
    end
    
    methods
        function obj = Subsystem(model_handle, model_path, subsystem)
            obj.handle = subsystem;
            obj.model_name = get_param(model_handle, 'Name');
            obj.model_path = model_path;
            obj.interface = Interface(subsystem);
        end

        function str = print(obj)
            str = "";
            str = str + obj.model_name + newline;
            str = str + obj.hash();
        end

        function hsh = hash(obj)
            hsh = obj.interface.hash();
        end

        function hsh = md5(obj)
            hsh = rptgen.hash(obj.hash());
        end
    end
end