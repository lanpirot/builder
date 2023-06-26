classdef Equivalence_class
    %Equivalency classes get created that hold 'equivalent' interfaces of
    %subsystems
    %'equivalent' being that the subsystems could be exchanged in the model
    properties
        hash
        subsystems;
    end

    methods
        function obj = Equivalence_class(subsystem)
            obj.hash = subsystem.interface.hash();
            obj.subsystems = {subsystem.name2subinfo()};
        end

        function obj = add_subsystem(obj, subsystem)
            if obj.hash ~= subsystem.interface.hash()
                throw(MException('Equivalence_class', 'This subsystem is not equivalent to others in class')) 
            end
            next_index = obj.get_index(subsystem);
            if next_index > 0 || ~Helper.remove_duplicates
                obj.subsystems = [obj.subsystems(1:next_index - 1) subsystem.name2subinfo() obj.subsystems(next_index:end)];
            end
        end

        function is_in = is_already_in(obj, subsystem)
            is_in = 1;
            for i=1:length(obj.subsystems)
                if subsystem.is_identical(obj.subsystems{i})
                    return
                end
            end
            is_in = 0;
        end

        function index = get_index(obj, subsystem)
            index = -1;
            left_wall = 1; right_wall = length(obj.subsystems); pivot = round((right_wall + left_wall)/2);
            while right_wall >= left_wall
                if subsystem.num_contained_elements < obj.subsystems{pivot}.NUM_CONTAINED_ELEMENTS
                    right_wall = pivot - 1;
                elseif subsystem.num_contained_elements > obj.subsystems{pivot}.NUM_CONTAINED_ELEMENTS
                    left_wall = pivot + 1;
                else
                    break
                end
                pivot = round((right_wall + left_wall)/2);
            end
            pivot = min(max(1, pivot), length(obj.subsystems));
            if ~subsystem.is_identical(obj.subsystems{pivot})
                if subsystem.num_contained_elements < obj.subsystems{pivot}.NUM_CONTAINED_ELEMENTS
                    index = pivot;
                else
                    index = pivot + 1;
                end
            end
        end
    end
end