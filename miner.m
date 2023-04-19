function miner()
    %warning('on','all')
    warning('off','all')
    
    project_dir = helper.project_dir;
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');

    hash_dic = dictionary(string([]), {});
    my_fileID = fopen(helper.subsystem_interfaces, "w+");
    fprintf(my_fileID,"Subsystem Path,Model Path,Project URL,Interface" + newline);
    fclose(my_fileID);

    evaluated = 0;
    
    for i = 1:height(modellist.model_url)
        if ~modellist.closable(i)
            continue
        end
        cd(project_dir)
        try
            rmdir(helper.garbage_out + "*", 's');
        catch
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
                
            catch
                disp("Skipping " + model_path)
                try_close(model_name, model_path);
                continue
            end
            hash_dic = compute_interfaces(hash_dic, model_handle, model_path, strip(modellist.project_url(i, :),"right"));

            try_end(model_name);
            try_close(model_name, model_path);
            evaluated = evaluated + 1;
        catch
            try_close(model_name, model_path);
        end
        %update startat
    end
    disp(evaluated)
    disp("Models evaluated of ")
    disp(height(modellist.model_url))
end

function hash_dic = compute_interfaces(hash_dic, model_handle, model_path, project_path)
    subsystems = find_system(model_handle, 'LookUnderMasks', 'On', 'BlockType', 'SubSystem');
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
    catch
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

    my_fileID = fopen(helper.subsystem_interfaces, "a+");
    fprintf(my_fileID, subsystem.print() + newline);
    fclose(my_fileID);
    if ~isempty(e.subsystems) && ~any(count(e.model_paths(), subsystem.model_path))
        disp("Doubled Interface found with: " + subsystem.hash)
    end

    e = e.add_subsystem(subsystem);
    hash_dic{subsystem.md5()} = e;
end