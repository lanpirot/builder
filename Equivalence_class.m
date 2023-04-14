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

        function paths = model_paths(obj)
            paths = {};
            for i = 1:length(obj.subsystems)
                paths = [paths ; obj.subsystems{i}.model_path];
            end
        end
    end
end