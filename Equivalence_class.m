classdef Equivalence_class
    properties
        subsystems;
    end

    methods
        function obj = Equivalence_class()
            obj.subsystems = {};
        end

        function obj = add_subsystem(obj, subsystem)
            obj.subsystems{end + 1} = subsystem;
        end

        function hsh = hash(obj)
            hsh = obj.subsystems{1}.hash();
        end

        function hsh = md5(obj)
            hsh = rptgen.hash(obj.hash());
        end
    end
end