function miner()
    warning('off','all')
    
    project_dir = helper.project_dir;
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');

    hash_dic = dictionary(string([]), {});

    reset_logs([helper.subsystem_interfaces, helper.log_garbage_out, helper.log_eval, helper.log_close])
    log(project_dir, 'subsystem_interfaces', "Subsystem Path,Model Path,Project URL,Interface")

    evaluated = 0;
    
    for i = 1:100%height(modellist.model_url)
        if ~modellist.compilable(i)
            continue
        end
        cd(project_dir)
        try
            rmdir(helper.garbage_out + "*", 's');
        catch ME
            log(project_dir, 'log_garbage_out', ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
        end
        mkdir(helper.garbage_out)
        cd(helper.garbage_out)
        

        model_path = string(strip(modellist.model_url(i, :),"right"));
        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');
            eval([model_name, '([],[],[],''compile'');']);
            cd(project_dir)
            disp("Evaluating number " + string(i) + " " + model_path)
            hash_dic = compute_interfaces(project_dir, hash_dic, model_handle, model_path, strip(modellist.project_url(i, :),"right"));

            try_end(model_name);
            try_close(model_name, model_path);
            evaluated = evaluated + 1;
        catch ME
            log(project_dir, 'log_eval', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            try_close(model_name, model_path);
        end
    end
    fprintf("\nFinished! %i models evaluated out of %i\n", evaluated, height(modellist.model_url))
end

function hash_dic = compute_interfaces(project_dir, hash_dic, model_handle, model_path, project_path)
    subsystems = helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;
    for j = 1:length(subsystems)
        hash_dic = compute_interface(project_dir, hash_dic, model_handle, model_path, project_path, subsystems(j));
    end
    disp("#subsystems analyzed: " + string(length(subsystems)) + " #equivalence classes: " + string(length(keys(hash_dic))))
    %for j = 1:length(interfaces)
    %    interfaces{j} = interfaces{j}.update_busses();
    %end
end

function interface = update_busses(interface)
    interface = interface.update_busses();
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

function hash_dic = compute_interface(project_dir, hash_dic, model_handle, model_path, project_path, subsystem)
    subsystem = Subsystem(model_handle, model_path, project_path, subsystem);
    if subsystem.skip_it
        return
    end
    if hash_dic.isKey(subsystem.md5())
        e = hash_dic{subsystem.md5()};
    else
        e = Equivalence_class();
    end

    log(project_dir, 'subsystem_interfaces', subsystem.print());
    if ~isempty(e.subsystems) && ~any(count(e.model_paths(), subsystem.model_path))
        disp("Doubled Interface found with: " + subsystem.hash)
    end

    e = e.add_subsystem(subsystem);
    hash_dic{subsystem.md5()} = e;
end

function log(project_dir, file_name, message)
    cd(project_dir)
    file_name = helper.(file_name);
    my_fileID = fopen(file_name, "a+");
    fprintf(my_fileID, replace(message, "\", "/") + newline);
    fclose(my_fileID);
end

function reset_logs(file_list)
    for i = 1:length(file_list)
        file = file_list(i);
        my_fileID = fopen(file, "w+");
        fprintf(my_fileID, "");
        fclose(my_fileID);
    end
end