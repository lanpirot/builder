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
            if ~obj.is_already_in(subsystem) || ~Helper.remove_duplicates
                obj.subsystems{end + 1} = subsystem.name2subinfo();
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
    end
end