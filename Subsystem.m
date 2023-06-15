classdef Subsystem
    properties
        handle
        name
        qualified_name
        model_name
        model_path
        project_path
        uuid            %uuid of the subsystem itself
        contained_uuids %uuids of direct children of the subsytem
        num_contained_elements
        is_root

        interface
        skip_it
        buses_present   %either in subsystem itself, or in decendants
        
        %currently broken?
        depth %relative max depth of sub tree
        diverseness %number of different block types in the sub tree
        %complexity %only if compilable set root to sub? https://www.mathworks.com/help/slcheck/ref/slmetric.metric.result.html
    end
    
    methods
        function obj = Subsystem(subsystem_handle, model_handle, model_path, project_path)
            obj.handle = subsystem_handle;
            obj.name = Subsystem.get_name(obj.handle);
            obj.qualified_name = SimulinkName.get_qualified_name(obj.handle);
            obj.model_name = get_param(model_handle, 'Name');
            obj.model_path = model_path;
            obj.project_path = project_path;

            obj.interface = Interface(obj.handle);
        end

        function obj = constructor2(obj)
            obj.uuid = Subsystem.get_uuid(obj.model_path, obj.qualified_name);
            obj.contained_uuids = Subsystem.get_uuids(Helper.get_contained_subsystems(obj.handle), obj.model_path);
            obj.num_contained_elements = length(Helper.find_elements(obj.handle));
            obj.buses_present = obj.buses_in_obj_or_ancestors();
            obj.skip_it = obj.buses_present || ~Subsystem.is_subsystem(obj.handle);
            if ~obj.skip_it
                obj = obj.compute_meta_data();
            end
        end

        function obj = compute_meta_data(obj)
            obj.is_root = SimulinkName.is_root(obj.handle);
            obj.depth = Helper.find_local_depth(obj.handle);
            obj.diverseness = Helper.find_diverseness(obj.handle);
            %obj.complexity = 0;
        end

        function bool = buses_in_obj_or_ancestors(obj)
            bool = 1;
            if obj.interface.has_buses
                return
            end
            contained_subsystems = Helper.get_contained_subsystems(obj.handle);
            for i = 1:length(contained_subsystems)
                inner_interface = Interface(contained_subsystems(i));
                if inner_interface.has_buses
                    return
                end
            end
            bool = 0;
        end

        function str = print(obj)
            uuids = join(Subsystem.get_uuids(Helper.get_contained_subsystems(obj.handle), obj.model_path), Helper.second_level_divider);
            if isempty(uuids)
                uuids = "";
            end
            str = join([obj.uuid uuids """"+obj.qualified_name+"""" obj.model_path obj.project_path obj.interface_hash()], Helper.first_level_divider);
        end

        function hsh = interface_hash(obj)
            hsh = obj.interface.hash();
        end

        function mapping = interface_mapping(obj)
            mapping = obj.interface.mapping();
        end

        function hsh = name_hash(obj)
            hsh = SimulinkName.name_hash(obj.model_path, obj.qualified_name);
        end
        
        function n2i = name2subinfo(obj)
            n2i = struct;
            n2i.(Helper.name) = obj.name_hash();
            n2i.(Helper.ntrf) = obj.interface_hash();
            n2i.(Helper.mapping) = obj.interface_mapping();
            n2i.(Helper.depth) = obj.depth;
            n2i.(Helper.diverseness) = obj.diverseness;
        end

        function bool = is_in_subs(obj, sub_index, subs)
            for i = 1:length(subs)
                if i~=sub_index && obj.num_contained_elements == subs{i}.num_contained_elements
                    bool = 1;
                    return
                end
            end
            bool = 0;
        end
    end



    methods (Static)
        function name = get_name(handle)
            name = get_param(handle, 'Name');
        end

        function bool = is_subsystem(handle)
            bool = length(Helper.find_elements(handle)) > 1;
        end

        function uuid = get_uuid(model_path, qname)
            uuid = rptgen.hash(string(model_path) + qname);
        end

        function uuids = get_uuids(handles, model_path)
            uuids = {};
            for i = 1:length(handles)
                uuids{end + 1} = Subsystem.get_uuid(model_path, SimulinkName.get_qualified_name(handles(i)));
            end
        end
    end
end