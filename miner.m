function miner()
    %warning('on','all')
    warning('off','all')
    
    %modellist = tdfread(helper.modellist, 'tab');
    modellist = tdfread(helper.tmp_modellist, 'tab');
    startat = readlines(helper.startat);
    startat = double(startat);

    hash_dic = dictionary(string([]), {});

    
    
    for i = startat:height(modellist.model_url)
        cd(helper.project_dir)
        %rmdir(helper.garbage_out + "*", 's');
        %mkdir(helper.garbage_out)
        %cd(helper.garbage_out)
        

        model_path = strip(modellist.model_url(i, :),"right");
        %try
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
        %catch
        %    try_close(model_name, m);
        %end
        %update startat
    end
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
    subsystem = Subsystem(model_handle, model_path, subsystem);
    if subsystem.interface.has_busses()
        return
    end
    if hash_dic.isKey(subsystem.md5())
        e = hash_dic{subsystem.md5()};
    else
        e = Equivalence_class();
    end
    e = e.add_subsystem(subsystem);
    hash_dic{subsystem.md5()} = e;
end