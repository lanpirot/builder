classdef Equivalence_class
    %Equivalency classes get created that hold 'equivalent' interfaces of
    %subsystems
    %'equivalent' being that the subsystems could be exchanged in the model
    properties
        hsh
        subsystems;
    end

    methods
        function obj = Equivalence_class()
            obj.subsystems = {};
        end

        function obj = add_subsystem(obj, subsystem)
            if length(obj.subsystems) < 1
                obj.hsh = subsystem.interface_hash();
            else
                if obj.hsh ~= subsystem.interface_hash()
                    throw(MException('Equivalence_class', 'This subsystem is not equivalent ot others in class')) 
                end
            end
            obj.subsystems{end + 1} = subsystem;
        end

        function hsh = hash(obj)
            hsh = obj.hsh;
        end

        function name_hashes = name_hashes(obj)
            name_hashes = {};
            for i = 1:length(obj.subsystems)
                name_hashes{end + 1} = obj.subsystems{i}.name_hash();
            end
        end

        function name_hashes = unique_name_hashes(obj)
            name_hashes = {};
            for i = 1:length(obj.subsystems)
                if ~obj.subsystems{i}.is_in_subs(i, obj.subsystems)
                    name_hashes{end + 1} = obj.subsystems{i}.name_hash();
                end
            end
        end
    end
end