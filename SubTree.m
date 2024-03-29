classdef SubTree
    properties
        identity
        children = [];                  %identities of all children of this subtree

        synthed_identity
        num_elements
        num_subsystems
        local_depth

        unique_models
        unique_subsystems
    end

    methods
        function is_discrepant_to_slx(obj)
            for i = 1:length(obj.children)
                obj.children{i}.is_discrepant_to_slx()
            end
            obj_handle = get_param(obj.synthed_identity.get_qualified_name(), "Handle");
            slx_num_elements = Helper.find_num_elements_in_contained_subsystems(obj_handle);
            slx_num_subsystems = length(Helper.get_contained_subsystems(obj_handle, 1000));
            if obj.num_elements ~= slx_num_elements || obj.num_subsystems - 1 ~= slx_num_subsystems
                disp("Warning: Discrepancy found between Theory-Model and actual slx-Model")
                disp(obj.synthed_identity)
                disp("")
            end
        end

        function obj = SubTree(sub, subinfos)
            obj.identity = Identity(sub);
            obj.children = subinfos{{sub}}.(Helper.children);
        end

        function obj = recursive_subtree(obj, subinfos)
            tmpchildren = obj.children;
            obj.children = [];
            for i = 1:length(tmpchildren)
                obj.children{i} = SubTree(tmpchildren(i), subinfos);
                obj.children{i} = obj.children{i}.recursive_subtree(subinfos);
            end
        end

        function bool = recursive_same_AST(obj, other_tree)
            bool = 1;
            if length(obj.children) ~= length(other_tree.children)
                bool = 0;
                return
            end
            for i = 1:length(obj.children)
                if ~ obj.children{i}.recursive_same_AST(other_tree.children{i})
                    bool = 0;
                    return
                end
            end
        end

        function [obj, model_handle, additional_level] = build_root(obj, model_name)
            global name2subinfo_complete
            slx_id = Identity(model_name, '', Helper.synthesize_playground + filesep + model_name);
            obj.synthed_identity = slx_id;
            
            
            close_system(slx_id.sub_name, 0)

            [slx_id, additional_level] = ModelMutator.copy_to_root(slx_id.sub_name, slx_id.model_path, obj.identity, slx_id);
            ModelMutator.make_subsystem_editable(slx_id.get_qualified_name());
            set_param(model_name, 'Lock', 'off')
            set_param(model_name, "LockLinksToLibrary", "off")
            ModelMutator.annotate(slx_id.get_qualified_name(), "Copied system from: " + obj.identity.hash() + newline + "to: " + slx_id.hash())
            close_system(obj.identity.model_path)
            
            slx_children = name2subinfo_complete{{struct(obj.identity)}}.(Helper.children);
            for i = 1:length(obj.children)
                obj.children{i} = obj.children{i}.build_sub(slx_children(i), slx_id, [slx_id.get_qualified_name()]);
            end
            model_handle = get_param(model_name, 'Handle');
        end

        function obj = build_sub(obj, copy_to, slx_id, slx_parents)
            global name2subinfo_complete
            copy_from = obj.identity;
            copy_to = Identity(copy_to);
            copy_into = Identity(copy_to.sub_name, slx_parents, slx_id.model_path);
            
            

            
            copy_from_interface = Interface(name2subinfo_complete{{struct(copy_from)}}.(Helper.interface));
            copy_to_interface = Interface(name2subinfo_complete{{struct(copy_to)}}.(Helper.interface));

            
            load_system(copy_from.model_path)
            mapping = copy_to_interface.get_mapping(copy_from_interface);
            copied_element = Identity(copy_from.sub_name, copy_into.sub_parents, slx_id.model_path);
            copy_into = ModelMutator.copy_to_non_root(copy_into, copy_from, copied_element, mapping);
            obj.synthed_identity = copy_into;
            ModelMutator.make_subsystem_editable(copy_into.get_qualified_name());
            ModelMutator.annotate(copy_into.get_qualified_name(), "Copied system from: " + copy_from.hash() + newline + "to: " + copy_to.hash())
            close_system(copy_from.model_path)

            slx_children = name2subinfo_complete{{struct(obj.identity)}}.(Helper.children);
            for i = 1:length(obj.children)
                obj.children{i} = obj.children{i}.build_sub(slx_children(i), slx_id, [slx_parents '/' copy_into.sub_name]);
            end
        end

        function obj = root_report(obj)
            obj = obj.report();
            obj.unique_models = unique(obj.unique_models);
            obj.unique_subsystems = unique(obj.unique_subsystems);
        end

        function obj = report(obj)
            global name2subinfo_complete
            global model2id
            local_elements = name2subinfo_complete{{struct(obj.identity)}}.(Helper.num_local_elements);
            if isempty(obj.children)
                obj.local_depth = 0;
                obj.num_elements = local_elements;
                obj.num_subsystems = 1;
                obj.unique_models = model2id(cellstr(obj.identity.model_path));
                obj.unique_subsystems = name2subinfo_complete{{struct(obj.identity)}}.sub_id;
            else
                subtree_local_depth = 0;
                subtree_num_elements = 0;
                subtree_num_subsystems = 0;
                all_models = [];
                all_subsystems = [];
                for i = 1:length(obj.children)
                    obj.children{i} = obj.children{i}.report();
                    subtree_local_depth = max(subtree_local_depth, obj.children{i}.local_depth);
                    subtree_num_elements = subtree_num_elements + obj.children{i}.num_elements;
                    subtree_num_subsystems = subtree_num_subsystems + obj.children{i}.num_subsystems;
                    all_models = [all_models obj.children{i}.unique_models];
                    all_subsystems = [all_subsystems obj.children{i}.unique_subsystems];
                end
                obj.local_depth = subtree_local_depth + 1;
                obj.num_elements = subtree_num_elements + local_elements;
                obj.num_subsystems = subtree_num_subsystems + 1;
                obj.unique_models = [all_models model2id(cellstr(obj.identity.model_path))];
                obj.unique_subsystems = [all_subsystems name2subinfo_complete{{struct(obj.identity)}}.sub_id];
            end
        end

        function obj = add_level(obj)
            obj.local_depth = obj.local_depth + 1;
            obj.num_elements = obj.num_elements + 2;
            obj.num_subsystems = obj.num_subsystems + 1;
        end
    end
end