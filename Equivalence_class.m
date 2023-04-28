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
            obj.subsystems{end + 1} = subsystem;
            obj.hsh = subsystem.interface_hash();
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