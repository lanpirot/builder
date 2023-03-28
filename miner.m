function miner()
    %warning('on','all')
    warning('off','all')
    
    modellist = tdfread(helper.modellist, 'tab');
    %modellist = tdfread(helper.tmp_modellist, 'tab');
    startat = readlines(helper.startat);
    startat = double(startat);

    cd(helper.garbage_out)
    
    for i = startat:height(modellist.model_url)
        %cd(helper.project_dir)
        %rmdir(helper.garbage_out + "*", 's');
        %mkdir(helper.garbage_out)
        

        model = strip(modellist.model_url(i, :),"right");
        try
            m = load_system(model);
            model_name = get_param(m, 'Name');
            try
                eval([model_name, '([],[],[],''compile'');']);
                %disp("Evaluating " + model)
            catch
                %disp("Skipping " + model)
                close_system(m)
                continue
            end
            subsystems = find_system(m, 'BlockType', 'SubSystem');
            for j = 1:length(subsystems)
                interface = find_interface(subsystems(j));
                %save_interface(interface);
            end
            try
                while 1
                    eval([model_name, '([],[],[],''term'');']);
                end
            catch
                close_system(m);
            end
        catch
        end
        %update startat
    end
end

function interface = find_interface(subsystem)
    interface = [];
    InportHandles = find_system(subsystem, 'FindAll','On', 'LookUnderMasks', 'on', 'SearchDepth',1, 'BlockType','Inport');
    OutportHandles = find_system(subsystem, 'FindAll','On', 'LookUnderMasks', 'on', 'SearchDepth',1, 'BlockType','Outport');
    disp("SS: " + get_param(subsystem, 'Name'))
    for i=1:length(InportHandles)
        
        InputDimensions = get_param(InportHandles(i),'CompiledPortDimensions');
        %InputDimensions = InputDimensions.Outport
        
        InputDataTypes = get_param(InportHandles(i),'CompiledPortDataTypes');
        %InputDataTypes = InputDataTypes.Outport
        %if length(InputDataTypes.Outport) > 1
            
            %disp(get_param(InportHandles(i), 'Name'))
            %disp(InputDimensions.Outport)
            %disp(InputDataTypes.Outport)
            disp(Simulink.Block.getSampleTimes(InportHandles(i)))
            disp(get_param(InportHandles(i), 'SampleTime'))
            if get_param(InportHandles(i), 'SampleTime') ~= -1 || ~strcmp('-1', get_param(InportHandles(i), 'SampleTime'))
                disp(get_param(InportHandles(i), 'SampleTime'))
            end
        %end
    end

end