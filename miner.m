function miner()
    %warning('on','all')
    warning('off','all')
    
    project_dir = helper.project_dir;
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');
    startat = readlines(helper.startat);
    startat = double(startat);

    hash_dic = dictionary(string([]), {});
    global fileID
    fileID = fopen("doubled interfaces", "w+");

    evaluated = 0;
    
    for i = 1:height(modellist.model_url)
        disp(i)
        cd(project_dir)
        %rmdir(helper.garbage_out + "*", 's');
        %mkdir(helper.garbage_out)
        %cd(helper.garbage_out)
        

        model_path = strip(modellist.model_url(i, :),"right");
        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');
            try
                eval([model_name, '([],[],[],''compile'');']);
                disp("Evaluating " + model_path)
                
            catch
                disp("Skipping " + model_path)
                try_close(model_name, model_handle);
                continue
            end
            hash_dic = compute_interfaces(hash_dic, model_handle, model_path);

            try_end(model_name);
            try_close(model_name, model_handle);
            evaluated = evaluated + 1;
        catch
            try_close(model_name, model_handle);
        end
        %update startat
    end
    disp(evaluated)
    disp("Models evaluated of ")
    disp(height(modellist.model_url))
end

function hash_dic = compute_interfaces(hash_dic, model_handle, model_path)
    subsystems = find_system(model_handle, 'BlockType', 'SubSystem');
    for j = 1:length(subsystems)
        hash_dic = compute_interface(hash_dic, model_handle, model_path, subsystems(j));
    end
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

function hash_dic = compute_interface(hash_dic, model_handle, model_path, subsystem)
    global fileID
    subsystem = Subsystem(model_handle, model_path, subsystem);
    if subsystem.skip_it
        return
    end
    if hash_dic.isKey(subsystem.md5())
        e = hash_dic{subsystem.md5()};
    else
        e = Equivalence_class();
    end
    if ~isempty(e.subsystems) && ~any(count(e.model_paths(), subsystem.model_path))
        fprintf(fileID, subsystem.hash + newline);
        disp(subsystem.hash)
    end

    e = e.add_subsystem(subsystem);
    hash_dic{subsystem.md5()} = e;
end