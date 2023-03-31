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
            interfaces = compute_interfaces(m, model_name);

            try_close(model_name, m);
        %catch
        %    try_close(model_name, m);
        %end
        %update startat
    end
end

function interfaces = compute_interfaces(m, model_name)
    subsystems = find_system(m, 'BlockType', 'SubSystem');
    interfaces = {};
    for j = 1:length(subsystems)
        i = compute_interface(m, subsystems(j));
        if ~i.has_busses
            interfaces{end + 1} = i;
        end
    end
    for i = 1:length(interfaces)-1
        for j = i+1:length(interfaces)
            if ~interfaces{i}.empty_interface && interfaces{i}.same_as(interfaces{j})
                disp(string(i) + " " + string(j))
                disp(interfaces{i}.print())
                disp(interfaces{j}.print())
            end
        end
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

function interface = compute_interface(model, subsystem)
    interface = Interface(subsystem);
end