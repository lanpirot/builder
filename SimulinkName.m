
%could handle all functions of providing either Name, Model Name, Handle,
%Ancestor, qualified Name etc.

classdef SimulinkName
    properties
        original_model_name
        original_full_name

        model_name
        full_name


        ancestor_names
        element_name
        is_root
    end
    
    methods
        function obj = SimulinkName(full_name, original_model_name)
            full_name = string(full_name);
            original_model_name = string(original_model_name);


            obj.full_name = full_name;
            split_name = split(full_name, "/");

            try
                obj.model_name = split_name{1};
            catch
                obj.model_name = split_name{1};
            end
            obj.ancestor_names = join(split_name(1:max(1, end-1)), "/");
            obj.element_name = split_name(end);
            obj.is_root = count(full_name,"/") == 0;


            obj.original_model_name = original_model_name;
            split_name{1} = char(obj.original_model_name);
            obj.original_full_name = join(split_name, "/");
        end
    end
end