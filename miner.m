function miner()
    %warning('on','all')
    warning('off','all')
    
    project_dir = helper.project_dir;
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');

    hash_dic = dictionary(string([]), {});

    reset_files([helper.subsystem_interfaces, helper.log_garbage_out, helper.log_load_system, helper.log_eval, helper.log_close])
    log(helper.subsystem_interfaces, "Subsystem Path,Model Path,Project URL,Interface")

    evaluated = 0;
    
    for i = 1:100%height(modellist.model_url)
        if ~modellist.compilable(i)
            continue
        end
        cd(project_dir)
        try
            rmdir(helper.garbage_out + "*", 's');
        catch ME
            log(helper.log_garbage_out, ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
        end
        mkdir(helper.garbage_out)
        cd(helper.garbage_out)
        

        model_path = strip(modellist.model_url(i, :),"right");
        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');
            try
                eval([model_name, '([],[],[],''compile'');']);
                cd(project_dir)
                disp("Evaluating number " + string(i) + " " + model_path)
                
            catch ME
                log(helper.log_load_system, ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                disp("Skipping " + model_path)
                try_close(model_name, model_path);
                continue
            end
            hash_dic = compute_interfaces(hash_dic, model_handle, model_path, strip(modellist.project_url(i, :),"right"));

            try_end(model_name);
            try_close(model_name, model_path);
            evaluated = evaluated + 1;
        catch ME
            log(helper.log_eval, ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            try_close(model_name, model_path);
        end
        %update startat
    end
    disp(evaluated)
    disp("Models evaluated of ")
    disp(height(modellist.model_url))
end

function hash_dic = compute_interfaces(hash_dic, model_handle, model_path, project_path)
    subsystems = find_system(model_handle, 'LookUnderMasks', 'On', 'BlockType', 'SubSystem'); %,'FollowLinks','on' to look into Library Subsystems
    subsystems(end + 1) = model_handle;
    for j = 1:length(subsystems)
        hash_dic = compute_interface(hash_dic, model_handle, model_path, project_path, subsystems(j));
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

function try_close(name, m)
    try_end(name)
    try
        close_system(m)
    catchME
        log(helper.log_close, ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
    end
end

function hash_dic = compute_interface(hash_dic, model_handle, model_path, project_path, subsystem)
    subsystem = Subsystem(model_handle, model_path, project_path, subsystem);
    if subsystem.skip_it
        return
    end
    if hash_dic.isKey(subsystem.md5())
        e = hash_dic{subsystem.md5()};
    else
        e = Equivalence_class();
    end

    log(helper.subsystem_interfaces, subsystem.print());
    if ~isempty(e.subsystems) && ~any(count(e.model_paths(), subsystem.model_path))
        disp("Doubled Interface found with: " + subsystem.hash)
    end

    e = e.add_subsystem(subsystem);
    hash_dic{subsystem.md5()} = e;
end

function log(file_name, message)
    my_fileID = fopen(file_name, "a+");
    fprintf(my_fileID, replace(message, "\", "/") + newline);
    fclose(my_fileID);
end

function reset_files(file_list)
    for i = 1:length(file_list)
        file = file_list(i);
        my_fileID = fopen(file, "w+");
        fprintf(my_fileID, "");
        fclose(my_fileID);
    end
end