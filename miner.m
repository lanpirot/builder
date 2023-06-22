function miner(max_number_of_models)
    warning('off','all')
    disp("Starting mining process")
    Helper.reset_logs([Helper.name2subinfo, Helper.log_garbage_out, Helper.log_eval, Helper.log_close])
    evaluated = 0;
    subs = {};
    project_dir = Helper.project_dir;
    needs_to_be_compilable = Helper.needs_to_be_compilable;

    modellist = tdfread(Helper.modellist, 'tab');
    if ~exist("max_number_of_models",'var')
        max_number_of_models = height(modellist.model_url);
    end
    for i = 147:max_number_of_models%height(modellist.model_url)
        if needs_to_be_compilable && ~modellist.compilable(i)
            continue
        end
        Helper.create_garbage_dir();

        model_path = string(strip(modellist.model_url(i, :), "right"));
        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');

            if needs_to_be_compilable
                eval([model_name, '([],[],[],''compile'');']);
            end
            cd(project_dir)
            disp("Mining interfaces of model no. " + string(i) + " " + model_path)
            subs = compute_interfaces(subs, model_handle, model_path);

            if needs_to_be_compilable
                try_end(model_name);
            end
            try_close(model_name, model_path);
            evaluated = evaluated + 1;
        catch ME
            if contains(pwd, "tmp_garbage")
                cd("..")
            end
            log(project_dir, 'log_eval', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            try_close(model_name, model_path);
        end
        if contains(pwd, "tmp_garbage")
            cd("..")
        end
        Helper.clear_garbage()
    end
    cd(project_dir)
    serialize(subs);
    fprintf("\nFinished! %i models evaluated out of %i\n", evaluated, height(modellist.model_url))
end

function serialize(subs)
    interface2sub  = dictionary();
    for i = 1:length(subs)
        hash = subs{i}.interface.hash();
        if isConfigured(interface2sub) && interface2sub.isKey(hash)
            eq = interface2sub(hash);
            eq = eq.add_subsystem(subs{i});
        else
            eq = Equivalence_class(subs{i});
        end
        interface2sub(hash) = eq;
    end

    %serialize sub_info
    subinfo = {};
    keys = interface2sub.keys();
    for i = 1:length(keys)
        subinfo = [subinfo interface2sub(keys(i)).subsystems];
    end
    Helper.file_print(Helper.name2subinfo, jsonencode(subinfo));
end

function subs = compute_interfaces(subs, model_handle, model_path)
    subsystems = Helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;%the root subsystem
    for j = 1:length(subsystems)
        subs = compute_interface(subs, subsystems(j), model_path);
    end
    %disp("#subsystems analyzed: " + string(length(subsystems)) + " #equivalence classes: " + string(length(keys(hash_dic))))
end

function subs = compute_interface(subs, subsystem_handle, model_path)
    subsystem = Subsystem(subsystem_handle, model_path);
    subsystem = subsystem.constructor2();
    if subsystem.skip_it
        return
    end

    subs{end + 1} = subsystem;
end

function try_end(name)
    try
        while 1
            eval([name, '([],[],[],''term'');']);
        end
    catch
    end
end

function try_close(name, model_path)
    try_end(name)
    try
        close_system(model_path)
    catch ME
        log(project_dir, 'log_close', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
    end
end

function log(project_dir, file_name, message)
    cd(project_dir)
    Helper.log(file_name, message);
end