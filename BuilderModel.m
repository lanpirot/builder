classdef BuilderModel
    properties
        uuid
        original_name
        original_path
        name
        root_model_path

        num_original_subsystems
        num_switched_subsystems

        built_correct
    end
    
    methods
        function obj = BuilderModel(uuid, root_model)
            obj.uuid = uuid;
            tmp = split(root_model.name, ":");
            obj.original_name = string(tmp{end});
            obj.name = "model" + string(obj.uuid);
            obj.original_path = root_model.model_path;
            obj.root_model_path = helper.playground + filesep + obj.name + extractAfter(root_model.model_path,strlength(root_model.model_path)-4);
            copyfile(obj.original_path, obj.root_model_path);
            load_system(obj.root_model_path)
            obj.num_original_subsystems = length(Subsystem.get_contained_subsystems(get_param(obj.name, 'Handle')));
            close_system(obj.root_model_path)
        end

        function obj = switch_subs_in_model(obj, name2interface, interface2name)
            %try
                load_system(obj.root_model_path);
                root_handle = get_param(obj.name, 'Handle');
                
                curr_depth = 1;
                while 1
                    sub_handles = helper.find_subsystems(root_handle);
                    for i = 1:length(sub_handles)
                        sub_handle = sub_handles(i);
                        if count(get_param(sub_handle, 'Parent'), "/") == curr_depth - 1 && Subsystem.is_subsystem(sub_handle)
                            obj = obj.switch_sub(root_handle, sub_handle, name2interface, interface2name);
                        end
                    end
                    curr_depth = curr_depth + 1;
                end
                close_system(obj.root_model_path);

                disp(sub_handles)
            %catch ME
                %helper.log('log_switch_up', string(jsonencode(obj)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                throw(ME) 
            %end
        end

        function obj = switch_sub(obj, root_handle, sub_handle, name2interface, interface2name)
            sub_complete_name = helper.name_hash(obj.original_path, obj.original_name + "/" + get_param(sub_handle, 'Name'));
            sub_interface = name2interface({char(sub_complete_name)});
            alternate_sub_names = interface2name(sub_interface);
            alternate_sub_names = alternate_sub_names{1};

            if length(alternate_sub_names) > 1
                obj = obj.switch_sub_with_sub(sub_handle, alternate_sub_names);
            end
        end

        function obj = switch_sub_with_sub(obj, sub_handle, alternate_sub_names)

        end

        function obj = check_models_correctness(obj)
            obj.built_correct = obj.loadable() && obj.compilable();
        end

        function ld = loadable(obj)
            try
                load_system(obj.path);
                ld = 1;
            catch
                ld = 0;
            end
        end

        function cp = compilable(obj)
            helper.make_garbage()
            project_dir = helper.project_dir;
            try
                eval([char(obj.name), '([],[],[],''compile'');']);
                cp = 1;
                eval([char(obj.name), '([],[],[],''term'');']);
                close_system(obj.path)
            catch
                cp = 0;
            end
            cd(project_dir)
            helper.clear_garbage();
        end
    end

    methods (Static)
        function eq_sub = find_eq_sub(sub, eq_classes)
            eq_sub = [];
            hash = sub.interface_hash();
            

        end
    end
end