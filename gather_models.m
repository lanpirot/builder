function gather_models(max_number_of_models)
    [project_dir, project_info, fileID, modellist] =  startinit();
    if ~exist("max_number_of_models", 'var')
        max_number_of_models = length(modellist);
    end


    for i = 1:max_number_of_models
        if i == 5446 %this model is so broken, it breaks out of the try-catch block
            continue
        end
        
        [project_url, model_url] = prepare_model(modellist, i, project_info, project_dir);
        [loadable, model_name] = try_load(model_url);
        compilable = try_compile(model_name, loadable);
        runnable = try_simulate(model_name, loadable, compilable);
        closable = try_close(model_url, model_name, loadable);
        clean_up();

        row = replace(model_url + sprintf('\t') + project_url + sprintf('\t') + string(loadable) + sprintf('\t') + string(compilable) + sprintf('\t') + string(runnable) + sprintf('\t') + string(closable), "\", "/") + newline;
        fprintf(fileID, "%s", row);
    end
    fclose(fileID);
    disp("Saved gathered model info to " + string(Helper.modellist))
end


function [loadable, model_name] = try_load(model_url)
    loadable = 0;
    model_name = '';
    try
        model_handle = load_system(model_url);
        model_name = get_param(model_handle, 'Name');
        loadable = 1;
    catch
    end
end

function compilable = try_compile(model_name, loadable)
    compilable = 0;
    if loadable
        try
            set_param(model_name, 'SimMechanicsOpenEditorOnUpdate', 'off')
        catch
        end
    
        try
            eval([model_name, '([],[],[],''compile'');']);
            compilable = 1;
        catch
        end
        try
            while 1
                eval([model_name, '([],[],[],''term'');']);
            end
        catch
        end
    end
end

function runnable = try_simulate(model_name, loadable, compilable)
    runnable = 0;
    if loadable && compilable
        try
            end_sim_time = 0.001;
            start_real_time = tic;
            while end_sim_time < 10 && toc(start_real_time) < 60
                out = sim(model_name, 'StartTime', '0', 'StopTime', string(end_sim_time));
                if ~isempty(out.ErrorMessage)
                    return
                end
                end_sim_time = end_sim_time * 2;
            end
            runnable = 1;
        catch
        end
    end
end

function closable = try_close(model_url, model_name, loadable)
    closable = 0;
    if loadable
        try
            close_system(model_url)
        catch            
        end
        closable = double(~bdIsLoaded(model_name));
    end
end

function [project_url, model_url] = prepare_model(modellist, i, project_info, project_dir)
    disp("Now gathering model no. " + string(i))
    model = modellist(i);
    if contains(model.name, ' ')
        movefile([model.folder filesep model.name], [model.folder filesep replace(model.name, ' ', '')])
        model.name = replace(model.name, ' ', '');
    end
    folder = strsplit(model.folder, filesep);
    %assumes, you unzipped SLNET projects to a directory each named by a number
    %did you forget a "/" at the end of the filename?
    project_id = double(string(folder{count(Helper.project_dir, filesep) + 2}));      
    
    
    project_info_row = find(project_info.path == project_id);
    project_url = project_info.url(project_info_row,:);
    project_url = Helper.rstrip(project_url);

    model_url = string(fullfile(model.folder, model.name));
    cd(project_dir)
    Helper.create_garbage_dir(mfilename)
end

function [project_dir, project_info, fileID, modellist] =  startinit()
    addpath(pwd)
    addpath(genpath('utils'), '-begin');
    set(0, 'DefaultFigureVisible', 'off');
    warning('off','all')


    disp("Starting gathering process")
    modellist = [dir(fullfile(Helper.models_path, "**" + filesep + "*.slx")); dir(fullfile(Helper.models_path, "**" + filesep + "*.mdl"))];
    project_dir = Helper.project_dir;
    project_info = tdfread(Helper.project_info, 'tab');
    fileID = fopen(Helper.modellist, "w+");
    fprintf(fileID, "model_url" + sprintf("\t") + "project_url" + sprintf("\t") + "loadable" + sprintf("\t") + "compilable" + sprintf("\t") + "runnable" + sprintf("\t") + "closable" + newline);
end

function clean_up()
    Helper.clear_garbage(mfilename);
    close all force;
    bdclose all
end