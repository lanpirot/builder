classdef Equivalence_class
    properties
        subsystems = {};
    end

    methods
        function obj = Equivalence_class(Subsystem)
            obj.subsystems{end + 1} = Subsystem;
        end

        function obj = add_subsystem(obj, Subsystem)
            obj.subsystems{end + 1} = Subsystem;
        end

        function hsh = hash(obj)
            hsh = obj.subsystems{1}.hash();
        end
    end
end