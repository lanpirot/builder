classdef SubTree
    properties
        identity
        children = [];                  %identities of all children of this subtree
    end

    methods
        function obj = SubTree(sub, subinfos, parents)
            obj.identity = Identity(sub);
            obj.children = subinfos{{sub}}.(Helper.children);
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

        function bool = is_leaf(obj)
            bool = isempty(obj.children);
        end

        function model_handle = build_root(obj)
            global name2subinfo_complete
            model_name = 'tmp';
            slx_id = Identity(model_name, '', Helper.synthesize_playground + filesep + model_name);
            try
                close_system(slx_id.sub_name)
            catch
                close_system(slx_id.sub_name, 0)
            end
            new_system(slx_id.sub_name);
            save_system(slx_id.sub_name, slx_id.model_path)

            load_system(obj.identity.model_path)
            slx_id = ModelMutator.copy_to_root(slx_id.sub_name, slx_id.model_path, obj.identity, slx_id);
            ModelMutator.make_subsystem_editable(slx_id.get_qualified_name());
            set_param(model_name, 'Lock', 'off')
            set_param(model_name, "LockLinksToLibrary", "off")
            close_system(obj.identity.model_path)
            ModelMutator.annotate(slx_id.get_qualified_name(), "Copied system from: " + obj.identity.hash() + newline + "to: " + slx_id.hash())
            
            slx_children = name2subinfo_complete{{struct(obj.identity)}}.(Helper.children);
            for i = 1:length(obj.children)
                obj.children{i}.build_sub(slx_children(i), slx_id, [slx_id.get_qualified_name()]);
            end
            model_handle = get_param(model_name, 'Handle');
        end

        function build_sub(obj, copy_to, slx_id, slx_parents)
            copy_from = obj.identity;
            copy_to = Identity(copy_to);
            copy_into = Identity(copy_to.sub_name, slx_parents, '');
            

            global name2subinfo_complete
            copy_from_interface = Interface(name2subinfo_complete{{struct(copy_from)}}.(Helper.interface));
            copy_to_interface = Interface(name2subinfo_complete{{struct(copy_to)}}.(Helper.interface));
            mapping = copy_to_interface.get_mapping(copy_from_interface);
            copied_element = Identity(copy_from.sub_name, copy_into.sub_parents, slx_id.model_path);

            load_system(copy_to.model_path)
            load_system(copy_from.model_path)
            ModelMutator.copy_to_non_root(copy_into, copy_from, copied_element, mapping)
            ModelMutator.make_subsystem_editable(copy_into.get_qualified_name());
            close_system(copy_from.model_path)
            close_system(copy_to.model_path)
            ModelMutator.annotate(copy_into.get_qualified_name(), "Copied system from: " + copy_from.hash() + newline + "to: " + copy_to.hash())

            slx_children = name2subinfo_complete{{struct(obj.identity)}}.(Helper.children);
            for i = 1:length(obj.children)
                obj.children{i}.build_sub(slx_children(i), slx_id, [slx_parents '/' copy_into.sub_name]);
            end
        end
    end
end