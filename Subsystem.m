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

        interface
        skip_it
        buses_present   %either in subsystem itself, or in decendants
        
        %currently broken?
        %max_depth %relative max depth in model tree from this Subsystem to its leaves
        %block_types
        %complexity
    end
    
    methods
        function obj = Subsystem(subsystem_handle, model_handle, model_path, project_path)
            obj.handle = subsystem_handle;
            obj.name = Subsystem.get_name(obj.handle);
            obj.qualified_name = Subsystem.get_qualified_name(obj.handle);
            obj.model_name = get_param(model_handle, 'Name');
            obj.model_path = model_path;
            obj.project_path = project_path;

            obj.interface = Interface(obj.handle);
        end

        function obj = construct2(obj)
            obj.uuid = Subsystem.get_uuid(obj.model_path, obj.qualified_name);
            obj.contained_uuids = Subsystem.get_uuids(Subsystem.get_contained_subsystems(obj.handle), obj.model_path);
            obj.num_contained_elements = length(find_system(obj.handle, 'LookUnderMasks', 'on', 'FollowLinks','on'));
            obj.buses_present = obj.buses_in_obj_or_ancestors();
            obj.skip_it = obj.buses_present || ~Subsystem.is_subsystem(obj.handle);
            if ~obj.skip_it
                obj.compute_meta_data()
            end
        end

        function compute_meta_data(obj)
            %own_depth = Helper.get_depth(get_param(obj.handle, 'Parent'));
            %contained_blocks = find_system(obj.handle,'LookUnderMasks','on', 'Type', 'Block');
            % obj.max_depth = 0;
            % obj.block_types = {};
            % for i = 1:length(contained_blocks)
            %     block = contained_blocks(i);
            %     obj.max_depth = max(obj.max_depth, Helper.get_depth(get_param(block, 'Parent')) - own_depth);
            %     block_type = get_param(block, 'BlockType');
            %     if ~any(count(obj.block_types, block_type))
            %         obj.block_types = [obj.block_types ; block_type];
            %     end
            % end
            %obj.complexity = 0;
        end

        function bool = buses_in_obj_or_ancestors(obj)
            bool = 1;
            if obj.interface.has_buses
                return
            end
            contained_subsystems = Subsystem.get_contained_subsystems(obj.handle);
            for i = 1:length(contained_subsystems)
                inner_interface = Interface(contained_subsystems(i));
                if inner_interface.has_buses
                    return
                end
            end
            bool = 0;
        end

        function str = print(obj)
            uuids = join(Subsystem.get_uuids(Subsystem.get_contained_subsystems(obj.handle), obj.model_path), Helper.second_level_divider);
            if isempty(uuids)
                uuids = "";
            end
            str = join([obj.uuid uuids """"+obj.qualified_name+"""" obj.model_path obj.project_path obj.interface_hash()], Helper.first_level_divider);
        end

        function hsh = interface_hash(obj)
            hsh = obj.interface.hash();
        end

        function hsh = name_hash(obj)
            hsh = Helper.name_hash(obj.model_path, obj.qualified_name);
        end
        
        function n2i = name2interface(obj)
            n2i = struct;
            n2i.name = obj.name_hash();
            n2i.ntrf = obj.interface_hash();
        end

        function r = is_root(obj)
            r = count(obj.qualified_name,"/") == 0;
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

        function qname = get_qualified_name(handle)
            if strlength(string(get_param(handle, 'Parent'))) > 0
                qname = string(get_param(handle, 'Parent')) + "/" + Subsystem.get_name(handle);
            else
                qname = Subsystem.get_name(handle);
            end
        end

        function bool = is_subsystem(handle)
            bool = length(find_system(handle,'LookUnderMasks','on')) > 1;
        end

        function uuid = get_uuid(model_path, qname)
            uuid = rptgen.hash(string(model_path) + qname);
        end

        function uuids = get_uuids(handles, model_path)
            uuids = {};
            for i = 1:length(handles)
                uuids{end + 1} = Subsystem.get_uuid(model_path, Subsystem.get_qualified_name(handles(i)));
            end
        end

        function subsystems = get_contained_subsystems(handle)
            pot_subsystems = Helper.find_subsystems(handle);
            subsystems = [];
            for i = 2:length(pot_subsystems)
                if Subsystem.is_subsystem(pot_subsystems(i))
                    subsystems(end + 1) = pot_subsystems(i);
                end
            end
        end
    end
end