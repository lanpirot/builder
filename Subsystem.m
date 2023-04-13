classdef Subsystem
    properties
        handle
        name
        qualified_name
        model_name
        model_path
        interface
        skip_it
        it_or_ancestors_have_buses
        
        max_depth %relative max depth in model tree from this Subsystem to its leaves
        block_types
        complexity
    end
    
    methods
        function obj = Subsystem(model_handle, model_path, subsystem)
            obj.handle = subsystem;
            obj.name = get_param(subsystem, 'Name');
            obj.qualified_name = string(get_param(subsystem, 'Parent')) + "/" + obj.name;
            obj.model_name = get_param(model_handle, 'Name');
            obj.model_path = model_path;
            obj.interface = Interface(subsystem);
            obj.it_or_ancestors_have_buses = obj.buses_in_obj_or_ancestors();
            obj.skip_it = obj.it_or_ancestors_have_buses || obj.interface.empty_interface;
            if ~obj.skip_it
                obj.compute_meta_data()
            end
        end

        function compute_meta_data(obj)
            own_depth = helper.get_depth(get_param(obj.handle, 'Parent'));
            contained_blocks = find_system(obj.handle, 'Type', 'Block');
            obj.max_depth = 0;
            obj.block_types = {};
            for i = 1:length(contained_blocks)
                block = contained_blocks(i);
                obj.max_depth = max(obj.max_depth, helper.get_depth(get_param(block, 'Parent')) - own_depth);
                block_type = get_param(block, 'BlockType');
                if ~any(count(obj.block_types, block_type))
                    obj.block_types = [obj.block_types ; block_type];
                end
            end
            %obj.complexity = 0;
        end

        function bool = buses_in_obj_or_ancestors(obj)
            bool = 1;
            if obj.interface.has_buses
                return
            end
            contained_subsystems = find_system(obj.handle, 'SearchDepth', 1, 'BlockType', 'SubSystem');
            for i = 1:length(contained_subsystems)
                inner_interface = Interface(contained_subsystems(i));
                if inner_interface.has_buses
                    return
                end
            end
            bool = 0;
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