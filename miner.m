function miner()
    warning('off','all')
    
    project_dir = helper.project_dir;
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');

    reset_logs([helper.interface2name, helper.interface2name_unique, helper.name2interface, helper.name2interface_roots, helper.log_garbage_out, helper.log_eval, helper.log_close])

    evaluated = 0;
    subs = {};
    
    for i = 1:100%height(modellist.model_url)
        if ~modellist.compilable(i)
            continue
        end
        helper.make_garbage();

        model_path = string(strip(modellist.model_url(i, :),"right"));
        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');
            eval([model_name, '([],[],[],''compile'');']);
            cd(project_dir)
            %disp("Evaluating number " + string(i) + " " + model_path)
            subs = compute_interfaces(subs, model_handle, model_path, strip(modellist.project_url(i, :),"right"));

            try_end(model_name);
            try_close(model_name, model_path);
            evaluated = evaluated + 1;
        catch ME
            log(project_dir, 'log_eval', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            try_close(model_name, model_path);
        end

        cd(project_dir)
        helper.clear_garbage()
    end
    cd(project_dir)
    serialize(subs);
    fprintf("\nFinished! %i models evaluated out of %i\n", evaluated, height(modellist.model_url))
end

function serialize(subs)
    %serialize name --> interface
    name2interface = {};
    name2interface_roots = {};

    for i = 1:length(subs)
        name2interface{end + 1} = subs{i}.name2interface();
        if subs{i}.is_root()
            name2interface_roots{end + 1} = subs{i}.name2interface();
        end
    end
    helper.file_print(helper.name2interface, jsonencode(name2interface));
    helper.file_print(helper.name2interface_roots, jsonencode(name2interface_roots));

    %serialize interface --> names
    interface2name = dictionary();
    interface2name_unique = dictionary();

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
    %transfrom Subsystem into full subsystem path in interface2name_unique
    
    interface2name_struct = {};
    interface2name_unique_struct = {};
    keys = interface2name.keys;

    for i = 1:length(keys)
        interface2name_struct{end + 1} = struct;
        interface2name_struct{end}.ntrf = keys(i);
        interface2name_struct{end}.names = interface2name(keys(i)).name_hashes();

        interface2name_unique_struct{end + 1} = struct;
        interface2name_unique_struct{end}.ntrf = keys(i);
        interface2name_unique_struct{end}.names = interface2name(keys(i)).unique_name_hashes();
    end

    helper.file_print(helper.interface2name, jsonencode(interface2name_struct));
    helper.file_print(helper.interface2name_unique, jsonencode(interface2name_unique_struct));
end

function subs = compute_interfaces(subs, model_handle, model_path, project_path)
    subsystems = helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;
    for j = 1:length(subsystems)
        subs = compute_interface(subs, model_handle, model_path, project_path, subsystems(j));
    end
    %disp("#subsystems analyzed: " + string(length(subsystems)) + " #equivalence classes: " + string(length(keys(hash_dic))))
end

function subs = compute_interface(subs, model_handle, model_path, project_path, subsystem_handle)
    subsystem = Subsystem(subsystem_handle, model_handle, model_path, project_path);
    subsystem = subsystem.construct2();
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
    helper.log(file_name, message);
end

function reset_logs(file_list)
    for i = 1:length(file_list)
        file = file_list(i);
        my_fileID = fopen(file, "w+");
        fprintf(my_fileID, "");
        fclose(my_fileID);
    end
end