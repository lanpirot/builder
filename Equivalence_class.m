classdef Equivalence_class
    properties
        hsh
        subsystems;
    end

    methods
        function obj = Equivalence_class()
            obj.subsystems = {};
        end

        function obj = add_subsystem(obj, subsystem)
            obj.subsystems{end + 1}.model_path = subsystem.model_path;
            obj.subsystems{end}.qualified_name = subsystem.qualified_name;
            obj.hsh = subsystem.interface_hash();
        end

        function hsh = hash(obj)
            hsh = obj.hsh;
        end
    end
end