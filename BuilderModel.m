classdef BuilderModel
    properties
        uuid
        name
        path
        root_model

        num_original_subsystems
        num_switched_subsystems

        built_correct
    end
    
    methods
        function obj = BuilderModel(uuid, root_model)
            obj.uuid = uuid;
            obj.name = "model" + string(obj.uuid);
            obj.path = helper.playground + filesep + obj.name + extractAfter(root_model.model_path,strlength(root_model.model_path)-4);
            copyfile(root_model.model_path, obj.path);



            obj.root_model = root_model;
            obj.num_original_subsystems = length(root_model.contained_uuids);
        end

        function obj = switch_up(obj)
            obj = obj;
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
end