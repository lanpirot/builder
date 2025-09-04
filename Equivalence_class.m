classdef Equivalence_class  < handle
    %Equivalency classes get created that hold 'equivalent' interfaces of
    %subsystems
    %'equivalent' being that the subsystems could be exchanged in the model
    properties
        hash
        subsystems;
    end

    methods
        function obj = Equivalence_class(subsystemS, hash)
            obj.hash = hash;
            if iscell(subsystemS)
                obj.subsystems = subsystemS;
            else
                obj.subsystems = {subsystemS};
            end
        end

        function obj = add_subsystem(obj, subsystem)
            obj.subsystems{end+1} = subsystem;
        end

        function ret = sort(obj)
            num_elements = cellfun(@(x) x.num_local_elements, obj.subsystems);

            [~, sortIdx] = sort(num_elements);
            ret = obj.subsystems(sortIdx);
        end

        function ret = remove_duplicates(obj)
            %Variation point: other, finer Subsystem information could be included
            %to determine duplicates
            num_elements = cellfun(@(x) x.num_local_elements, obj.subsystems, 'UniformOutput', false);
            subtree_depth = cellfun(@(x) x.subtree_depth, obj.subsystems, 'UniformOutput', false);
            num_children  = cellfun(@(x) length(x.direct_children), obj.subsystems, 'UniformOutput', false);

            composite_keys = cellfun(@(ne, sd, nc) sprintf('%d_%d_%d', ne, sd, nc), ...
                                     num_elements, subtree_depth, num_children, 'UniformOutput', false);
            [~, uniqueIdx] = unique(composite_keys);

            ret = Equivalence_class(obj.subsystems(uniqueIdx), obj.hash);
        end

        function obj = less_fields(obj)
            subs = {};
            for i=1:length(obj.subsystems)
                subs{end + 1} = obj.subsystems{i}.less_fields();
            end
            obj.subsystems = subs;
        end

        function index = get_index(obj, subsystem)
            index = -1;
            left_wall = 1; right_wall = length(obj.subsystems); pivot = round((right_wall + left_wall)/2);
            while right_wall >= left_wall
                if subsystem.num_local_elements < obj.subsystems{pivot}.num_local_elements
                    right_wall = pivot - 1;
                elseif subsystem.num_local_elements > obj.subsystems{pivot}.num_local_elements
                    left_wall = pivot + 1;
                else
                    break
                end
                pivot = round((right_wall + left_wall)/2);
            end
            pivot = min(max(1, pivot), length(obj.subsystems));
            if ~subsystem.is_identical(obj.subsystems{pivot})
                if subsystem.num_local_elements < obj.subsystems{pivot}.num_local_elements
                    index = pivot;
                else
                    index = pivot + 1;
                end
            end
        end
    end
end