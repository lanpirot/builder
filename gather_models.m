function gather_models()
    [project_dir, project_info, fileID, modellist, start_num] =  startinit();
    max_number_of_models = length(modellist);

    for i = start_num:max_number_of_models
        warning('off','all')
        
        [project_url, model_url] = prepare_model(modellist, i, project_info, project_dir);
        [loadable, model_name] = try_load(model_url);
        compilable = try_compile(model_name, loadable);
        runnable = try_simulate(model_name, loadable, compilable);
        closable = try_close(model_url, model_name, loadable);
        clean_up_internal();

        row = replace(model_url + sprintf(",") + project_url + sprintf(",") + string(loadable) + sprintf(",") + string(compilable) + sprintf(",") + string(runnable) + sprintf(",") + string(closable), "\", "/") + newline;
        fprintf(fileID, "%s", row);
    end    
    fclose(fileID);
    disp("Saved gathered model info to " + string(Helper.cfg().modellist))
    Helper.clear_garbage();
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
            set_param(model_name, 'SimulationCommand', 'start');
            set_param(model_name, 'SimulationCommand', 'pause');
            start_real_time = tic;
            sim_time = 0;
            while sim_time < 1 && toc(start_real_time) < 15
                set_param(model_name, 'SimulationCommand', 'step')
                sim_time = get_param(model_name, 'SimulationTime');
             end
            runnable = double(sim_time > 0);
            set_param(model_name, 'SimulationCommand', 'stop')
        catch
        end
    end
end

function out = wrappedSim(model_name)
    out = sim(model_name);
end

function closable = try_close(model_url, model_name, loadable)
    closable = 0;
    if loadable
        try
            close_system(model_url, 0)
        catch            
        end
        closable = double(~bdIsLoaded(model_name));
    end
end

function [project_url, model_url] = prepare_model(modellist, i, project_info, project_dir)
    disp("Now gathering model no. " + string(i) + " " + string(modellist(i).name))
    model = modellist(i);
    if contains(model.name, ' ')
        movefile([model.folder filesep model.name], [model.folder filesep replace(model.name, ' ', '')])
        model.name = replace(model.name, ' ', '');
    end
    folder = strsplit(model.folder, filesep);

    %assumes, you unzipped SLNET projects to a directory each named by a number
    %did you forget a "/" at the end of the filename?
    project_id = double(string(folder{count(Helper.cfg().project_dir, filesep) + 3}));      
    
    
    project_info_row = find(project_info.path == project_id);
    project_url = project_info.url(project_info_row,:);
    project_url = Helper.rstrip(project_url);

    model_url = string(fullfile(model.folder, model.name));
    cd(project_dir)
    Helper.create_garbage_dir()
end

function [project_dir, project_info, fileID, modellist, start_num] =  startinit()
    addpath(pwd)
    addpath(genpath('utils'), '-begin');
    set(0, 'DefaultFigureVisible', 'off');
    warning('off','all')


    disp("Starting gathering process")
    Helper.cfg('reset');
    modellist = [dir(fullfile(Helper.cfg().models_path, "**" + filesep + "*.slx")); dir(fullfile(Helper.cfg().models_path, "**" + filesep + "*.mdl"))];
    project_dir = Helper.cfg().project_dir;
    project_info = tdfread(Helper.cfg().project_info, 'tab');

    if ~isfile(Helper.cfg().modellist)
        fileID = fopen(Helper.cfg().modellist, "w+");
        fprintf(fileID, "model_url" + sprintf(",") + "project_url" + sprintf(",") + "loadable" + sprintf(",") + "compilable" + sprintf(",") + "runnable" + sprintf(",") + "closable" + newline);
    else
        fileID = fopen(Helper.cfg().modellist, "a");
    end
    start_num = numel(strsplit(fileread(Helper.cfg().modellist), '\n'));
    if start_num == 2
        start_num = 1;
    end
end

function clean_up_internal()
    close all force;
    try
        bdclose all
    catch 
    end
end