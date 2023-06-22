classdef Subsystem
    properties
        handle
        name
        qualified_name
        parents
        ancestors
        model_path
        model_name
        
        is_root

        interface
        skip_it
        buses_present   %either in subsystem itself, or in decendants
        num_contained_elements
        sub_depth
        subtree_depth %relative max depth of sub tree
        diverseness %number of different block types in the sub tree
        %complexity %only if compilable set root to sub? https://www.mathworks.com/help/slcheck/ref/slmetric.metric.result.html
    end
    
    methods
        function obj = Subsystem(subsystem_handle, model_path)
            if ~exist('model_path', 'var')%unloaded subsystem, getting called from ModelBuilder
                sub = subsystem_handle;
                obj.name = sub.(Helper.identity).(Helper.sub_name);
                obj.parents = sub.(Helper.identity).(Helper.sub_parents);
                obj = obj.get_qualified_name();
                obj.model_path = sub.(Helper.identity).(Helper.model_path);
                obj.model_name = Helper.get_model_name(obj.model_path);
                obj.is_root = sub.(Helper.is_root);
                obj.interface = Interface(sub.(Helper.interface));
                obj.skip_it = 0;
                obj.sub_depth = sub.(Helper.sub_depth);
                obj.subtree_depth = sub.(Helper.subtree_depth);
                obj.diverseness = sub.(Helper.diverseness);
                obj.num_contained_elements = sub.(Helper.num_contained_elements);
                return
            end
            obj.handle = subsystem_handle;
            obj.name = get_param(obj.handle, 'Name');
            obj.parents = get_param(obj.handle, 'Parent');
            obj = obj.get_qualified_name();
            obj.model_path = model_path;
            obj.model_name = Helper.get_model_name(obj.model_path);

            obj.interface = Interface(obj.handle);
        end

        function obj = constructor2(obj)
            obj.num_contained_elements = length(Helper.find_elements(obj.handle));
            obj.buses_present = obj.buses_in_subtree();
            obj.skip_it = obj.buses_present || ~Subsystem.is_subsystem(obj.handle);
            if ~obj.skip_it
                obj = obj.compute_meta_data();
            end
        end

        function obj = compute_meta_data(obj)
            obj.is_root = Helper.is_rootf(obj.handle);
            obj.sub_depth = Helper.get_depth(obj.handle);
            obj.subtree_depth = Helper.find_local_depth(obj.handle);
            obj.diverseness = Helper.find_diverseness(obj.handle);
            %obj.complexity = 0;
        end

        function bool = buses_in_subtree(obj)
            bool = 1;
            if obj.interface.skip_interface
                return
            end
            contained_subsystems = Helper.get_contained_subsystems(obj.handle);
            for i = 1:length(contained_subsystems)
                inner_interface = Interface(contained_subsystems(i));
                if inner_interface.skip_interface
                    return
                end
            end
            bool = 0;
        end

        function identity = get_identity(obj)
            identity = Identity(obj.name, obj.parents, obj.model_path);
        end
        
        function n2i = name2subinfo(obj)
            n2i = struct;
            n2i.(Helper.identity) = obj.get_identity();
            n2i.(Helper.interface) = obj.interface;

            n2i.(Helper.is_root) = obj.is_root;
            n2i.(Helper.sub_depth) = obj.sub_depth;
            n2i.(Helper.subtree_depth) = obj.subtree_depth;
            n2i.(Helper.diverseness) = obj.diverseness;
            n2i.(Helper.num_contained_elements) = obj.num_contained_elements;
        end

        function eq = is_equivalent(obj, other_subsystem)
            try
                eq = obj.interface.is_equivalent(other_subsystem.interface);
            catch
                eq = obj.interface.is_equivalent(other_subsystem.(Helper.interface));
            end
        end

        function eq = is_identical(obj, other_subsystem)
            try
                eq = obj.is_equivalent(other_subsystem) && obj.num_contained_elements == other_subsystem.num_contained_elements;%if changed here, look for other occurences
            catch
                eq = obj.is_equivalent(other_subsystem) && obj.num_contained_elements == other_subsystem.(Helper.num_contained_elements);%if changed here, look for other occurences
            end
        end

        function obj = get_qualified_name(obj)
            if ~isempty(obj.parents)
                obj.qualified_name = [obj.parents '/' obj.name];
                obj.ancestors = obj.parents;
            else
                obj.qualified_name = obj.name;
                obj.ancestors = obj.model_name;
            end
        end

        function hshid = hash_identity(obj)
            hshid = [obj.name char(Helper.second_level_divider) obj.parents char(Helper.second_level_divider) obj.model_path];
        end
    end



    methods (Static)
        function bool = is_subsystem(handle)
            bool = length(Helper.find_elements(handle)) > 1;
        end
    end
end