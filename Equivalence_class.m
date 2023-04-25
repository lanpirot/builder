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
            hsh = obj.subsystems{1}.interface_hash();
        end

        function paths = model_paths(obj)
            paths = {};
            for i = 1:length(obj.subsystems)
                paths = [paths ; obj.subsystems{i}.model_path];
            end
        end

        function str = string_hash_subsystems(obj)
            uuids = "";
            for i = 1:length(obj.subsystems)
                uuids = uuids + obj.subsystems{i}.uuid + helper.second_level_divider;
            end
            str = join([obj.hash uuids], helper.first_level_divider);
            %str = str + newline;
        end

        function str = weed_out_clones(obj)
            %weed out
        end
    end
end