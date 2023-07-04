classdef SubTree
    properties
        identity
        children = [];                  %identities of all children of this subtree
    end

    methods
        function obj = SubTree(sub)

        end

        function bool = is_leaf(obj)
            bool = isempty(obj.children);
        end
    end
end