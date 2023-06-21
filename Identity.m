classdef Identity
    properties
        sub_name
        parents
        model_path
    end

    methods
        function obj = Identity(identity)
            obj.sub_name = identity.(Helper.sub_name);
            obj.parents = identity.(Helper.sub_parents);
            obj.model_path = identity.(Helper.model_path);
        end

        function hsh = hash(obj)
            hsh = [obj.sub_name  ';' obj.parents ';' obj.model_path];
        end
    end

    methods (Static)
        function identical = is_identical(obj1, obj2)
            identical = strcmp(obj1.(Helper.sub_name), obj2.(Helper.sub_name)) && strcmp(obj1.(Helper.sub_parents), obj2.(Helper.sub_parents)) && strcmp(obj1.(Helper.model_path), obj2.(Helper.model_path));
        end
    end
end