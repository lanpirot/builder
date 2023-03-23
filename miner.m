function miner()
    warning('off','all')
    modellist = tdfread(helper.modellist, 'tab');
    startat = readlines(helper.startat);
    startat = double(startat);
    for i = startat:height(modellist.model_url)
        model = strip(modellist.model_url(i, :),"right");
        m = load_system(model);
        model_name = get_param(m, 'Name');
        try
            eval([model_name, '([],[],[],''compile'');']);
            disp("Evaluating " + model)
        catch
            disp("Skipping " + model)
            close_system(m)
            continue
        end
        subsystems = find_system(m, 'BlockType', 'SubSystem');
        for j = 1:length(subsystems)
            interface = find_interface(subsystems(j));
            %save_interface(interface);
        end
        try
            eval([model_name, '([],[],[],''term'');']);
            eval([model_name, '([],[],[],''term'');']);
            eval([model_name, '([],[],[],''term'');']);
        catch
        end
        close_system(m);
        %update startat
    end
end

function interface = find_interface(subsystem)
    interface = [];
    InportHandles = find_system(subsystem, 'FindAll','On', 'SearchDepth',1, 'BlockType','Inport');
    
    for i=1:length(InportHandles)
        
        InputDimensions = get_param(InportHandles(i),'CompiledPortDimensions');
        %InputDimensions = InputDimensions.Outport
        
        InputDataTypes = get_param(InportHandles(i),'CompiledPortDataTypes');
        %InputDataTypes = InputDataTypes.Outport
        if length(InputDataTypes.Outport) > 1
            disp("SS: " + get_param(subsystem, 'Name'))
            disp(get_param(InportHandles(i), 'Name'))
            disp(InputDimensions.Outport)
            disp(InputDataTypes.Outport)
        end
    end
end