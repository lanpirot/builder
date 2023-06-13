classdef SimulinkName
    properties
        original_model_name
        original_full_name

        model_name
        
        full_name
        element_name
        ancestor_names
        
        root_bool
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
            obj.root_bool = count(full_name,"/") == 0;


            obj.original_model_name = original_model_name;
            split_name{1} = char(obj.original_model_name);
            obj.original_full_name = join(split_name, "/");
        end
    end

    methods(Static)
        function str = name_hash(model_path, qualified_name)
            str = model_path + Helper.second_level_divider + qualified_name;
        end

        function qname = get_qualified_name(handle)
            if strlength(string(get_param(handle, 'Parent'))) > 0
                qname = string(get_param(handle, 'Parent')) + "/" + Subsystem.get_name(handle);
            else
                qname = Subsystem.get_name(handle);
            end
        end

        function q_name = get_qualified_name_from_handle(model_name, handle)
            q_name = split(SimulinkName.get_qualified_name(handle), "/");
            if length(q_name) > 1
                q_name(1) = model_name;
                q_name = join(q_name, "/");
            else
                q_name = model_name;
            end
        end

        function [model_name, sub_qualified_name] = unfuse_hash(fused_hash)
            split_up = split(fused_hash, Helper.second_level_divider);
            model_name = split_up{1};
            sub_qualified_name = split_up{2};
        end

        function bool = is_root(subsystem)
            bool = strlength(get_param(subsystem, 'Parent')) == 0;
        end
    end
end