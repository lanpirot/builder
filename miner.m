function miner(max_number_of_models)
    warning('off','all')
    Helper.reset_logs([Helper.interface2name, Helper.interface2name_unique, Helper.name2subinfo, Helper.name2subinfo_roots, Helper.log_garbage_out, Helper.log_eval, Helper.log_close])
    evaluated = 0;
    subs = {};
    project_dir = Helper.project_dir;

    modellist = tdfread(Helper.modellist, 'tab');
    for i = 1:max_number_of_models%height(modellist.model_url)
        if Helper.needs_to_be_compilable && ~modellist.compilable(i)
            continue
        end
        Helper.create_garbage_dir();

        model_path = string(strip(modellist.model_url(i, :), "right"));
        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');

            if Helper.needs_to_be_compilable
                eval([model_name, '([],[],[],''compile'');']);
            end
            cd(project_dir)
            disp("Mining interfaces of model no. " + string(i) + " " + model_path)
            subs = compute_interfaces(subs, model_handle, model_path, strip(modellist.project_url(i, :), "right"));

            if Helper.needs_to_be_compilable
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

        Helper.clear_garbage()
    end
    cd(project_dir)
    serialize(subs);
    fprintf("\nFinished! %i models evaluated out of %i\n", evaluated, height(modellist.model_url))
end

function serialize(subs)
    %serialize name --> interface
    name2subinfo = {};
    name2subinfo_roots = {};

    for i = 1:length(subs)
        name2subinfo{end + 1} = subs{i}.name2subinfo();
        if subs{i}.is_root
            name2subinfo_roots{end + 1} = subs{i}.name2subinfo();
        end
    end
    Helper.file_print(Helper.name2subinfo, jsonencode(name2subinfo));
    Helper.file_print(Helper.name2subinfo_roots, jsonencode(name2subinfo_roots));


    %serialize interface --> names
    interface2name = dictionary();

    for i = 1:length(subs)
        ntrf_hash = subs{i}.interface_hash();
        if isConfigured(interface2name) && interface2name.isKey(ntrf_hash)
            eq = interface2name(ntrf_hash);
        else
            eq = Equivalence_class();
        end
        eq = eq.add_subsystem(subs{i});
        interface2name(ntrf_hash) = eq;
    end
    
    
    interface2name_struct = {};
    interface2name_unique_struct = {};
    keys = interface2name.keys;

    for i = 1:length(keys)
        interface2name_struct{end + 1} = struct;
        interface2name_struct{end}.(Helper.ntrf) = keys(i);
        interface2name_struct{end}.(Helper.names) = interface2name(keys(i)).name_hashes();

        interface2name_unique_struct{end + 1} = struct;
        interface2name_unique_struct{end}.(Helper.ntrf) = keys(i);
        interface2name_unique_struct{end}.(Helper.names) = interface2name(keys(i)).unique_name_hashes();
    end

    Helper.file_print(Helper.interface2name, jsonencode(interface2name_struct));
    Helper.file_print(Helper.interface2name_unique, jsonencode(interface2name_unique_struct));
end

function subs = compute_interfaces(subs, model_handle, model_path, project_path)
    subsystems = Helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;%the root subsystem
    for j = 1:length(subsystems)
        subs = compute_interface(subs, subsystems(j), model_handle, model_path, project_path);
    end
    %disp("#subsystems analyzed: " + string(length(subsystems)) + " #equivalence classes: " + string(length(keys(hash_dic))))
end

function subs = compute_interface(subs, subsystem_handle, model_handle, model_path, project_path)
    subsystem = Subsystem(subsystem_handle, model_handle, model_path, project_path);
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