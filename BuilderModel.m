classdef BuilderModel
    properties
        uuid
        root_model

        num_original_subsystems
        num_switched_subsystems

        built_correct
    end
    
    methods
        function obj = BuilderModel(uuid, root_model)
            obj.uuid = uuid;
            name = "model" + string(obj.uuid);
            path = helper.playground + filesep + name + extractAfter(root_model.model_path,strlength(root_model.model_path)-4);
            copyfile(root_model.model_path, path);
            load_system(path)
            obj.root_model = Subsystem(get_param(name, 'Handle'), get_param(name, 'Handle'), path, "NaN");
            close_system(path)
            obj.num_original_subsystems = length(root_model.contained_uuids);
        end

        function obj = switch_subs_in_model(obj, eq_classes)
            %try
                load_system(obj.root_model.model_path);
                
                curr_depth = 1;
                while 1
                    subsystems = helper.find_subsystems(obj.root_model.name);
                    for i = 1:length(subsystems)
                        sub = subsystems{i};
                        if count(sub, "/") == curr_depth && Subsystem.is_subsystem(sub)
                            obj = obj.switch_sub(sub, eq_classes);
                        end
                    end
                    curr_depth = curr_depth + 1;
                end

                disp(subsystems)
            %catch ME
                %helper.log('log_switch_up', string(jsonencode(obj)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                throw(ME) 
            %end
        end

        function obj = switch_sub(obj, sub, eq_classes)
            sub = Subsystem(get_param(sub, 'Handle'), obj.root_model.handle, obj.root_model.model_path, obj.root_model.project_path);
            eq_sub = BuilderModel.find_eq_sub(sub, eq_classes);
            if ~isempty(eq_sub)
                obj = obj.switch_sub_with_sub(sub, eq_sub);
            end
        end

        function obj = switch_sub_with_sub(obj)

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