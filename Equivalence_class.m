classdef Equivalence_class
    %Equivalency classes get created that hold 'equivalent' interfaces of
    %subsystems
    %'equivalent' being that the subsystems could be exchanged in the model
    properties
        hash
        is_chimerable = 0;          %at least two subsystems (of two different models) in this class are chimerable themselves
        subsystems;
    end

    methods
        function obj = Equivalence_class(subsystem)
            obj.hash = subsystem.interface.hash();
            obj.subsystems = {subsystem};
        end

        function obj = add_subsystem(obj, subsystem)
            if ~strcmp(obj.hash, subsystem.interface.hash())
                throw(MException('Equivalence_class', 'This subsystem is not equivalent to others in class')) 
            end
            obj.subsystems{end+1} = subsystem;
        end

        function obj = sort(obj)
            num_elements = cellfun(@(x) x.num_local_elements, obj.subsystems);
            [~, sortIdx] = sort(num_elements);
            obj.subsystems = obj.subsystems(sortIdx);
        end

        function obj = remove_duplicates(obj)
            num_elements = cellfun(@(x) x.num_local_elements, obj.subsystems);
            [~, uniqueIdx] = unique(num_elements);
            obj.subsystems = obj.subsystems(uniqueIdx);
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

        function bool = check_chimerability(obj)
            bool = obj.is_chimerable;
            if bool
                return
            end
            for c=1:length(obj.subsystems)-1
                if obj.subsystems{c}.is_chimerable                    
                    for i=c+1:length(obj.subsystems)
                        if obj.subsystems{i}.is_chimerable && ~strcmp(obj.subsystems{c}.identity.model_path, obj.subsystems{i}.identity.model_path)
                            bool = 1;
                            return
                        end
                    end
                end
            end
        end

        function obj = remove_non_chimerable(obj, identity2sub)
            subsystems2 = {};
            for i = 1:length(obj.subsystems)
                sub = obj.subsystems{i};
                if identity2sub(sub.identity).is_chimerable
                    subsystems2{end + 1} = sub;
                end
            end
            obj.subsystems = subsystems2;
        end
    end
end