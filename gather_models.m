function gather_models(max_number_of_models)
    disp("Starting gathering process")
    warning('off','all')
    modellist = [dir(fullfile(Helper.models_path, "**" + filesep + "*.slx")); dir(fullfile(Helper.models_path, "**" + filesep + "*.mdl"))];
    project_dir = Helper.project_dir;
    project_info = tdfread(Helper.project_info, 'tab');
    fileID = fopen(Helper.modellist, "w+");
    fprintf(fileID, "model_url" + sprintf("\t") + "project_url" + sprintf("\t") + "loadable" + sprintf("\t") + "compilable" + sprintf("\t") + "closable" + newline);
    if ~exist("max_number_of_models",'var')
        max_number_of_models = length(modellist);
    end    
    for i = 1:max_number_of_models
        disp("Now gathering model no. " + string(i))
        cd(project_dir)
        model = modellist(i);
        if contains(model.name, ' ')
            movefile([model.folder filesep model.name], [model.folder filesep replace(model.name, ' ', '')])
            model.name = replace(model.name, ' ', '');
        end
        folder = strsplit(model.folder, filesep);
        project_id = double(string(folder{Helper.project_id_pwd_number}));
        project_info_row = find(project_info.path == project_id);
        project_url = project_info.url(project_info_row,:);
        project_url = Helper.rstrip(project_url);

        model_url = string(model.folder) + filesep + model.name;

        loadable = 0;
        compilable = 0;
        closable = 0;

        try
            model_handle = load_system(model_url);
            model_name = get_param(model_handle, 'Name');
            loadable = 1;
            try
                Helper.create_garbage_dir()
                eval([model_name, '([],[],[],''compile'');']);
                compilable = 1;
                try
                    while 1
                        eval([model_name, '([],[],[],''term'');']);
                    end
                catch
                end

                try
                    close_system(model_url);
                    closable = 1;
                catch
                end
            catch
                close_system(model_url);
                closable = 1;
            end
            if contains(pwd, "tmp_garbage")
                cd("..")
            end
            Helper.clear_garbage();
        catch
        end
        
        row = replace(model_url + sprintf('\t') + project_url + sprintf('\t') + string(loadable) + sprintf('\t') + string(compilable) + sprintf('\t') + string(closable), "\", "/") + newline;
        fprintf(fileID, row);
    end
    fclose(fileID);
    disp("Saved gathered model info to " + string(Helper.modellist))
end
        