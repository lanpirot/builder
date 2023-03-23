function gathermodels()
    modellist = [dir(fullfile(helper.models_path, '**\*.slx')); dir(fullfile(helper.models_path, '**\*.mdl'))];
    project_info = tdfread(helper.project_info, 'tab');
    fileID = fopen(helper.modellist, "w+");
    for i = 1:length(modellist)
        model = modellist(i);
        folder = strsplit(model.folder, '\');
        project_id = double(string(folder{8}));
        project_info_row = find(project_info.path == project_id);
        project_url = project_info.url(project_info_row,:);
        project_url = helper.rstrip(project_url);

        model_url = string(model.folder) + filesep + model.name;
        
        row = replace(model_url + sprintf('\t') + project_url, "\", "/") + newline;
        fprintf(fileID, row);
    end
    fclose(fileID);
end
        