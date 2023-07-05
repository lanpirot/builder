classdef Identity
    properties
        sub_name
        sub_parents
        model_path
    end

    methods
        function obj = Identity(sn, sp, mp)
            if ~exist('sp', 'var')
                identity = sn;
                obj.sub_name = identity.(Helper.sub_name);
                obj.sub_parents = identity.(Helper.sub_parents);
                obj.model_path = identity.(Helper.model_path);
                return
            end
            obj.sub_name = replace(sn, '/', '//');
            obj.sub_parents = sp;
            obj.model_path = mp;
        end

        function obj = set_name(obj, name)
            obj.sub_name = replace(name, '/', '//');
        end

        function hsh = hash(obj)
            hsh = [obj.sub_name  ';' obj.sub_parents ';' char(obj.model_path)];
        end

        function q_name = get_qualified_name(obj)
            if obj.is_root()
                q_name = obj.sub_name;
            else
                q_name = [obj.sub_parents '/' obj.sub_name];
            end
        end

        function is_root = is_root(obj)
            is_root = isempty(obj.sub_parents);
        end
    end

    methods (Static)
        function identical = is_identical(obj1, obj2)
            identical = strcmp(obj1.(Helper.sub_name), obj2.(Helper.sub_name)) && strcmp(obj1.(Helper.sub_parents), obj2.(Helper.sub_parents)) && strcmp(obj1.(Helper.model_path), obj2.(Helper.model_path));
        end
    end
end