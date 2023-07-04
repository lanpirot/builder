classdef SubTree
    properties
        identity
        children = [];                  %identities of all children of this subtree
    end

    methods
        function obj = SubTree(sub, subinfos)
            obj.identity = Identity(sub);
            subinfo = subinfos({sub});
            obj.children = subinfo{1}.(Helper.children);
        end

        function new_target = adapt_target_local(obj, curr_metric_target)
            switch Helper.synth_target_metric
                case Helper.synth_random
                    new_target = curr_metric_target;
            end
        end

        function new_target = adapt_target_descendants(obj, sub_metric, curr_metric_target)
            switch Helper.synth_target_metric
                case Helper.synth_random
                    new_target = curr_metric_target;
            end
        end

        function bool = is_metric_met(obj, curr_metric_target, metric_target)
            switch Helper.synth_target_metric
                case Helper.synth_random
                    bool = 1;
            end
        end

        function slx_identity = build_root(obj)
            slx_identity = Identity("", "", "");
        end

        function build_sub(obj, model, insertion_point)
            %recursively
        end

        function bool = is_leaf(obj)
            bool = isempty(obj.children);
        end
    end
end