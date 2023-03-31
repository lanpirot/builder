function miner()
    %warning('on','all')
    warning('off','all')
    
    %modellist = tdfread(helper.modellist, 'tab');
    modellist = tdfread(helper.tmp_modellist, 'tab');
    startat = readlines(helper.startat);
    startat = double(startat);

    

    
    
    for i = startat:height(modellist.model_url)
        cd(helper.project_dir)
        %rmdir(helper.garbage_out + "*", 's');
        %mkdir(helper.garbage_out)
        %cd(helper.garbage_out)
        

        model = strip(modellist.model_url(i, :),"right");
        %try
            m = load_system(model);
            model_name = get_param(m, 'Name');
            try
                eval([model_name, '([],[],[],''compile'');']);
                disp("Evaluating " + model)
            catch
                disp("Skipping " + model)
                try_close(model_name, m);
                continue
            end
            compute_interfaces(m, model_name);

            try_close(model_name, m);
        %catch
        %    try_close(model_name, m);
        %end
        %update startat
    end
end

function hash_dic = compute_interfaces(m, model_name)
    subsystems = find_system(m, 'BlockType', 'SubSystem');
    hash_dic = dictionary(string([]), {});
    for j = 1:length(subsystems)
        hash_dic = compute_interface(hash_dic, m, subsystems(j));
    end
    try_end(model_name);
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

function hash_dic = compute_interface(hash_dic, model, subsystem)
    subsystem = Subsystem(model, subsystem);
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