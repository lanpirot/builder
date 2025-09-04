classdef Subsystem < handle
    properties
        handle
        identity
        interface

        
        num_local_elements = -1;
        local_depth = -1;
        subtree_depth = -1;
        direct_children = {};
        skip = 0;
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
            obj.identity = Identity(get_param(obj.handle, 'Name'), get_param(obj.handle, 'Parent'), model_path);
            obj.interface = Interface(obj.handle);
            obj = obj.skip_it();
            if obj.skip
                return
            end
            obj = obj.compute_fields();
            %disp(obj.interface.)
        end

        function obj = compute_fields(obj)
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
            eq = Identity.is_identical(obj.identity, other_subsystem.identity);
        end

        function obj = skip_it(obj)
            bool = obj.interface.skip;
            try
                bool = bool || startsWith(get_param(obj.handle,'ReferenceBlock'), obj.identity.get_model_name()); %|| any(strcmp({'unresolved','breakWithoutHierarchy','restore','propagate','restoreHierarchy','propagateHierarchy'},get_param(obj.handle, 'LinkStatus')))
            catch
            end

            subs_to_test = Helper.find_subsystems(obj.handle);
            if isfloat(subs_to_test)
                bool = bool || any(startsWith(get_param(subs_to_test,'MaskType'),'ROS'));
            end
            obj.skip = bool;
        end
    end



    methods (Static)
        function bool = is_subsystem(handle)
            bool = length(Helper.find_elements(handle)) > 1;
            try
                get_param(handle, "MATLABFunctionConfiguration");
                bool = 0;
            catch
            end
        end


    end
end