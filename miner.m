function miner()
    warning('off','all')
    
    project_dir = helper.project_dir;
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');

    hash_dic = dictionary(string([]), {});

    reset_logs([helper.equivalence_classes, helper.equivalence_classes_no_clones, helper.root_interfaces, helper.interfaces, helper.log_garbage_out, helper.log_eval, helper.log_close])
    log(project_dir, 'root_interfaces', helper.interface_header)
    log(project_dir, 'interfaces', helper.interface_header)

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
            %disp("Evaluating number " + string(i) + " " + model_path)
            hash_dic = compute_interfaces(project_dir, hash_dic, model_handle, model_path, strip(modellist.project_url(i, :),"right"));

            try_end(model_name);
            try_close(model_name, model_path);
            evaluated = evaluated + 1;
        catch ME
            log(project_dir, 'log_eval', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            try_close(model_name, model_path);
        end
    end
    cd(project_dir)
    serialize(hash_dic, project_dir);
    fprintf("\nFinished! %i models evaluated out of %i\n", evaluated, height(modellist.model_url))
end

function serialize(hash_dic, project_dir)
    hash_dic_keys = keys(hash_dic);
    for i = 1:length(hash_dic_keys)
        eq = hash_dic{hash_dic_keys(i)};
        subsystems = eq.subsystems;
        
        %print hash_dic_keys(i) and md5s of each contained subsystem
        %write into helper.equivalence_classes
        log(project_dir, "equivalence_classes", eq.string_hash_subsystems());

        %weed out subsystems with same names and heuristically equal content
        %write into helper.equivalence_classes_no_clones
        %eq = eq.weed_out_clones();
        %log(project_dir, "equivalence_classes_no_clones", eq.string_hash_subsystems());
    end
end

function hash_dic = compute_interfaces(project_dir, hash_dic, model_handle, model_path, project_path)
    subsystems = helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;
    for j = 1:length(subsystems)
        hash_dic = compute_interface(project_dir, hash_dic, model_handle, model_path, project_path, subsystems(j));
    end
    %disp("#subsystems analyzed: " + string(length(subsystems)) + " #equivalence classes: " + string(length(keys(hash_dic))))
end

function hash_dic = compute_interface(project_dir, hash_dic, model_handle, model_path, project_path, subsystem)
    subsystem = Subsystem(model_handle, model_path, project_path, subsystem);
    if subsystem.skip_it
        return
    end
    if hash_dic.isKey(subsystem.interface_hash())
        e = hash_dic{subsystem.interface_hash()};
    else
        e = Equivalence_class();
    end

    if count(subsystem.qualified_name, "/") == 0
        log(project_dir, 'root_interfaces', subsystem.print());
        
    end
    log(project_dir, 'interfaces', subsystem.print());

    e = e.add_subsystem(subsystem);
    hash_dic{subsystem.interface_hash()} = e;
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