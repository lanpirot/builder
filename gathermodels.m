function gathermodels()
    modellist = [dir(fullfile(helper.models_path, '**\*.slx')); dir(fullfile(helper.models_path, '**\*.mdl'))];
    project_info = tdfread(helper.project_info, 'tab');
    fileID = fopen(helper.modellist, "w+");
    fprintf(fileID, "model_url" + sprintf("\t") + "project_url" + sprintf("\t") + "loadable" + sprintf("\t") + "compilable" + sprintf("\t") + "closable" + newline)
    for i = 1:length(modellist)
        model = modellist(i);
        folder = strsplit(model.folder, '\');
        project_id = double(string(folder{8}));
        project_info_row = find(project_info.path == project_id);
        project_url = project_info.url(project_info_row,:);
        project_url = helper.rstrip(project_url);

        model_url = string(model.folder) + filesep + model.name;

        %model_handle = load_system(model_path);
        %model_name = get_param(model_handle, 'Name');
        %eval([model_name, '([],[],[],''compile'');']);
        %eval([name, '([],[],[],''term'');']);
        %close_system(model_handle)
        loadable = 0;
        compilable = 0;
        closable = 0;

        try
            model_handle = load_system(model_url);
            model_name = get_param(model_handle, 'Name');
            loadable = 1;
            try
                eval([model_name, '([],[],[],''compile'');']);
                compilable = 1;
                try
                    while 1
                        eval([model_name, '([],[],[],''term'');']);
                    end
                catch
                end

                try
                    close_system(model_handle)
                    closable = 1;
                catch
                end
            catch
            end
        catch
        end
        
        row = replace(model_url + sprintf('\t') + project_url + sprintf('\t') + string(loadable) + sprintf('\t') + string(compilable) + sprintf('\t') + string(closable), "\", "/") + newline;
        fprintf(fileID, row);
    end
    fclose(fileID);
end
        