%% 
%% 
function gather_models()
    [project_dir, fileID, modellist, start_num] =  startinit();
    max_number_of_models = length(modellist);
    [~, idx] = sort({modellist.date});
    modellist = modellist(idx);

    for i = start_num:max_number_of_models
        warning('off','all')
        
        model_url = prepare_model(modellist, i, project_dir);
        [loadable, model_name] = try_load(model_url);

        [num_els, num_subs, depth] = try_measure(model_name);
        compilable = try_compile(model_name, loadable);
        runnable = try_simulate(model_name, loadable, compilable);
        closable = try_close(model_url, model_name, loadable);
        clean_up_internal();


        fields = strrep(strjoin([model_url, string(loadable), string(compilable), string(runnable), string(closable), string(num_els), string(num_subs), string(depth)], '\t'), "\", "/");
        fprintf(fileID, "%s\n", fields);
        Helper.clear_garbage();
    end    
    end_clean_up(fileID)
end


function [loadable, model_name] = try_load(model_url)
    loadable = 0;
    model_name = '';
    try
        model_handle = Helper.with_preserved_cfg(@load_system, model_url);
        model_name = get_param(model_handle, 'Name');
        loadable = 1;
    catch
    end
end

function [num_els, num_subs, depth] = try_measure(model_name)
    num_els = length(Helper.find_elements(model_name));
    num_subs = length(Helper.find_subsystems(model_name));
    depth = Helper.find_subtree_depth(model_name);
end

function compilable = try_compile(model_name, loadable)
    compilable = 0;
    if loadable
        try
            set_param(model_name, 'SimMechanicsOpenEditorOnUpdate', 'off')
        catch
        end
    
        try
            Helper.with_preserved_cfg(@(name) eval([name, '([],[],[],''compile'');']), model_name)
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
            Helper.with_preserved_cfg(@close_system, model_url, 0);
            bdclose all;
        catch
            bdclose all;
        end
        closable = double(~bdIsLoaded(model_name));
    end
end

function model_url = prepare_model(modellist, i, project_dir)
    disp("Now gathering model no. " + string(i) + " " + string(modellist(i).name))
    model = modellist(i);
    if contains(model.name, ' ')
        movefile([model.folder filesep model.name], [model.folder filesep replace(model.name, ' ', '')])
        model.name = replace(model.name, ' ', '');
    end

    model_url = string(fullfile(model.folder, model.name));
    cd(project_dir)
    Helper.create_garbage_dir()
end

function [project_dir, fileID, modellist, start_num] =  startinit()
    addpath(pwd)
    addpath(genpath('utils'), '-begin');
    set(0, 'DefaultFigureVisible', 'off');
    warning('off','all')


    disp("Starting gathering process")
    Helper.cfg('reset');
    modellist = [dir(fullfile(Helper.cfg().tame_models_path, "**" + filesep + "*.slx")); dir(fullfile(Helper.cfg().tame_models_path, "**" + filesep + "*.mdl"))];
    project_dir = Helper.cfg().project_dir;

    if isfile(Helper.cfg().modellist)
        fileID = fopen(Helper.cfg().modellist, "a");
        fprintf(fileID, "%s\n", strjoin(["broken_model" "NaN" "NaN" "NaN" "NaN" "NaN" "NaN" "NaN"], '\t'));
    else
        fileID = fopen(Helper.cfg().modellist, "w+");
        headers = ["model_url", "loadable", "compilable", "runnable", "closable", "num_els", "num_subs", "depth"];
        fprintf(fileID, "%s\n", strjoin(headers, '\t'));
    end
    start_num = count(fileread(Helper.cfg().modellist),newline);
end

function end_clean_up(fileID)
    fclose(fileID);
    disp("Saved gathered model info to " + string(Helper.cfg().modellist))
    disp("All done!")
end

function clean_up_internal()
    close all force;
    try
        bdclose all
    catch 
    end
end