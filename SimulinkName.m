classdef SimulinkName
    properties
        model_name
        ancestor_names
        element_name
        full_name
        is_root
    end
    
    methods
        function obj = SimulinkName(full_name)
            obj.full_name = full_name;
            split_name = split(full_name, "/");

            obj.model_name = split_name(1);
            obj.ancestor_names = join(split_name(1:end-1), "/");
            obj.element_name = split_name(end);
            obj.is_root = count(full_name,"/") == 0;
        end
    end
end