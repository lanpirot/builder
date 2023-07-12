classdef Subsystem
    properties
        handle
        identity
        interface

        
        num_local_elements = -1;
        local_depth = -1;
        subtree_depth = -1;
        direct_children = {};

        is_chimerable = 0;  %a subsystem without buses + either a leaf subsystem or all children without buses + all children could be swapped with compatible ones from other models
    end
    
    methods
        function obj = Subsystem(subsystem_handle, model_path)
            if ~exist('model_path', 'var')%unloaded subsystem, getting called from ModelBuilder
                sub = subsystem_handle;

                obj.identity = Identity(sub.(Helper.identity));
                obj.interface = Interface(sub.(Helper.interface));
                obj.num_local_elements = sub.(Helper.num_local_elements);
                obj.local_depth = sub.(Helper.local_depth);
                obj.subtree_depth = sub.(Helper.subtree_depth);
                obj.direct_children = sub.(Helper.children);                
                return
            end
            obj.handle = subsystem_handle;
            obj.interface = Interface(obj.handle);
            if obj.skip()
                return
            end
            obj = obj.compute_fields(model_path);
        end

        function obj = compute_fields(obj, model_path)
            obj.identity = Identity(get_param(obj.handle, 'Name'), get_param(obj.handle, 'Parent'), model_path);
            obj.num_local_elements = length(Helper.find_elements(obj.handle, 1));
            obj.local_depth = Helper.get_depth(obj.handle);
            obj.subtree_depth = Helper.find_subtree_depth(obj.handle);
            obj = obj.get_direct_children();
        end

        function obj = get_direct_children(obj)
            obj.direct_children = Helper.get_contained_subsystems(obj.handle, 1);
            dc = {};
            for i = 1:length(obj.direct_children)
                child = obj.direct_children(i);
                dc{end + 1} = Identity(get_param(child, 'Name'), get_param(child, 'Parent'), obj.identity.model_path);
            end
            obj.direct_children = dc;
            if isempty(obj.direct_children)
                obj.is_chimerable = 1;
            end
        end

        function ir = is_root(obj)
            ir = obj.identity.is_root();
        end
        
        function fields = less_fields(obj)
            fields = struct;
            fields.(Helper.identity) = obj.identity;
            fields.(Helper.interface) = obj.interface;

            fields.(Helper.num_local_elements) = obj.num_local_elements;
            fields.(Helper.local_depth) = obj.local_depth;
            fields.(Helper.subtree_depth) = obj.subtree_depth;
            fields.(Helper.children) = obj.direct_children;
        end

        function eq = is_identical(obj, other_subsystem)
            try
                other_interface = other_subsystem.interface;
                other_num_local_el = other_subsystem.num_local_elements;
            catch
                other_interface = other_subsystem.(Helper.interface);
                other_num_local_el = other_subsystem.(Helper.num_local_elements);
            end
            eq = obj.interface.is_equivalent(other_interface) && obj.num_local_elements == other_num_local_el;
        end

        function bool = skip(obj)
            bool = obj.interface.skip;
        end

        function [obj, is_chimerable] = propagate_chimerability(obj, interface2subs, identity2sub)
            if obj.skip()
                dips("")
            end
            is_chimerable = 0;
            if obj.is_chimerable
                return
            end
            for i = 1:length(obj.direct_children)
                if ~identity2sub.isKey(obj.direct_children{i})
                    return
                end
                if  ~interface2subs(identity2sub(obj.direct_children{i}).interface.hash()).is_chimerable
                    return
                end
            end
            obj.is_chimerable = 1;
            is_chimerable = 1;
        end
    end



    methods (Static)
        function bool = is_subsystem(handle)
            bool = length(Helper.find_elements(handle)) > 1;
        end
    end
end