function mine()
    TODO: remove old file of other mine procedure
    for needs_to_be_compilable = 1:1
        [old_path,models_evaluated,subs,modellist,models_mined] = startinit(needs_to_be_compilable);
        max_number_of_models = height(modellist.model_url);
        for i = 1:max_number_of_models
            if height(models_mined) >= i && models_mined.include(i) == 0
                continue
            end
            
            models_mined.include(i) = 0;
            models_mined.number(i) = i;
            writetable(models_mined, Helper.cfg().models_mined)
            path(old_path);
        
            if (needs_to_be_compilable && ~modellist.compilable(i)) || ~modellist.loadable(i) || ~modellist.closable(i)
                continue
            end
            Helper.create_garbage_dir();


            try
                [model_path, model_name, subsystems_of_model] = prepare_model(modellist.model_url(i, :));
    
                if is_architecture_model(model_name) || model_is_problem_file(model_name) || endsWith(model_path, "logger.slx")
                    cd(Helper.cfg().project_dir)
                    continue
                end
    
                if needs_to_be_compilable
                    Helper.with_preserved_cfg(@(name) eval([name, '([],[],[],''compile'');']), model_name)
                end
                cd(Helper.cfg().project_dir)
                disp("Mining interfaces of model no. " + string(i) + " " + model_path)
                subs = compute_interfaces_for_subs(subs, model_path, subsystems_of_model);
    
                if needs_to_be_compilable
                    try_end(model_name);
                end
                try_close(model_name, model_path);
                models_evaluated = models_evaluated + 1;
            catch ME
                cd(Helper.cfg().project_dir)
                log(Helper.cfg().project_dir, 'log_eval', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                try_close(model_name, model_path);
            end
            cd(Helper.cfg().project_dir)
            Helper.clear_garbage()
            close all force;

            writetable(models_mined, Helper.cfg().models_mined)
        end
        disp("We analyzed " + string(length(subs)) + " Subsystems altogether.")
        subs = remove_skips(subs);
        disp(string(length(subs)) + " Subsystems were taken into account (no bus ports present etc.).")
    
        %identity2sub = dic_id2sub(subs); %only needed for chimerability
        interface2subs = dic_int2subs(subs);
        serialize(interface2subs);
        fprintf("\nFinished! %i models evaluated out of %i\n", models_evaluated, height(modellist.model_url))
        cd(Helper.cfg().origin)
    end
end

function [model_path, model_name, subsystems] = prepare_model(raw_model_url)
    model_path = string(strip(raw_model_url, "right"));
    model_handle = Helper.with_preserved_cfg(@load_system, model_path);
    model_name = get_param(model_handle, 'Name');
    try
        set_param(model_name, 'SimMechanicsOpenEditorOnUpdate', 'off')
    catch
    end
    subsystems = Helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;%the root subsystem
end

function bool = is_architecture_model(model_name)
    try
        systemcomposer.loadModel(model_name);%skip architecture models
        close(model_name)
        try_close(model_name, model_path)                
        bool = true;
    catch
        bool = false;
    end
end

function bool = model_is_problem_file(name)
    bool = strcmp(name, 'hdlsllib') || 0; %fill with other problematic files, i.e. models with names that clash with auto-loaded models
end

function subs2 = remove_skips(subs)
    subs2 = {};
    for i = 1:length(subs)
        if ~subs{i}.skip
            subs2{end + 1} = remove_missing_children(subs{i}, i, subs);
        end
    end
end

function sub = remove_missing_children(sub, i, subs)
    model_path = sub.identity.model_path;
    children = sub.direct_children;
    found_children = {};
    for c = 1:length(children)
        found = 0;
        delta = 1;
        while i + delta <= length(subs) && strcmp(subs{i + delta}.identity.model_path, model_path)
            if Identity.is_identical(children{c}, subs{i + delta}.identity)
                found = ~subs{i + delta}.skip;
                break
            end
            delta = delta + 1;
        end
        delta = 1;
        while ~found && i > delta && strcmp(subs{i - delta}.identity.model_path, model_path)
            if Identity.is_identical(children{c}, subs{i - delta}.identity)
                found = ~subs{i - delta}.skip;
                break
            end
            delta = delta + 1;
        end
        if found
            found_children{end + 1} = children{c};
        end
    end
    sub.direct_children = found_children;
end

function interface2subs = remove_non_chimerable(interface2subs, identity2sub)
    ks = interface2subs.keys();
    for i = 1:length(ks)
        eq = interface2subs(ks(i));
        eq = eq.remove_non_chimerable(identity2sub);
        if isempty(eq) || ~eq.is_chimerable
            interface2subs(ks(i)) = [];
        else
            interface2subs(ks(i)) = eq;
        end
    end
end

function interface2subs = dic_int2subs(subs)
    interface2subs  = dictionary();
    for i = 1:length(subs)
        hash = subs{i}.interface.hash();
        if isConfigured(interface2subs) && interface2subs.isKey(hash)
            eq = interface2subs(hash);
            eq = eq.add_subsystem(subs{i});
        else
            eq = Equivalence_class(subs{i});
        end
        interface2subs(hash) = eq;
    end
end

function identity2sub = dic_id2sub(subs)
    identity2sub = dictionary();
    for i = 1:length(subs)
        if subs{i}.skip
            continue
        end
        identity2sub(subs{i}.identity) = subs{i};
    end
end

function [interface2subs, identity2sub] = propagate_chimerability(subs, interface2subs, identity2sub)
    %make subs-list
    ikeys = interface2subs.keys();
    subs2 = {};
    for i = 1:length(subs)
        eq = interface2subs(subs{i}.interface.hsh).subsystems;
        for j = 1:length(eq)
            if Identity.is_identical(eq{j}.identity, subs{i}.identity)
                subs2{end + 1} = subs{i};
                break
            end
        end
    end
    subs = subs2;


    %initialize dictionary is_chimerable values with leave nodes
    chimerable_count = 0;
    for i = 1:length(subs)
        if subs{i}.is_chimerable
            chimerable_count = chimerable_count + 1;
            interface2subs(subs{i}.interface.hash()).is_chimerable = 1;
        end
    end

    %propagate
    propagation_rounds = 1;
    found_propagation = 1;
    while found_propagation
        propagation_rounds = propagation_rounds + 1;
        found_propagation = 0;
        for i = 1:length(subs)
            [subs{i}, is_chimerable] = subs{i}.propagate_chimerability(interface2subs, identity2sub);
            if is_chimerable
                chimerable_count = chimerable_count + 1;
                interface2subs(subs{i}.interface.hash()).is_chimerable = interface2subs(subs{i}.interface.hash()).check_chimerability();
                identity2sub(subs{i}.identity).is_chimerable = 1;
                found_propagation = 1;
            end
        end
    end
    disp("We propagated is_chimerable to " + string(chimerable_count) + " subsystems in " + string(propagation_rounds) + " rounds.")
end

function serialize(interface2subs)
    %serialize sub_info
    subinfo = {};
    ikeys = interface2subs.keys();

    for i = 1:length(ikeys)
        interface2subs(ikeys(i)) = interface2subs(ikeys(i)).sort();
        subinfo = [subinfo interface2subs(ikeys(i)).less_fields().subsystems];
    end
    Helper.file_print(Helper.cfg().name2subinfo_complete, jsonencode(subinfo));
    [ikeys, identities] = make_i2s_smaller(interface2subs);
    Helper.file_print(Helper.cfg().interface2subs, jsonencode({ikeys, identities}))
    string_prefix = "Before";
    disp(string_prefix + " deleting duplicates, " + string(length(subinfo)) + " subsystems remain in " + string(length(keys(interface2subs))) + " interfaces.")


    subinfo = {};
    for i = 1:length(ikeys)
        subinfo = [subinfo interface2subs(ikeys(i)).remove_duplicates().subsystems];
    end
    Helper.file_print(Helper.cfg().name2subinfo, jsonencode(subinfo));
    disp("After" + " deleting duplicates, " + string(length(subinfo)) + " subsystems remain in " + string(length(keys(interface2subs))) + " interfaces.")
end

function [ikeys, identities] = make_i2s_smaller(i2s)
    ikeys = i2s.keys();
    identities = {};
    for i = 1:length(ikeys)
        ids = {};
        subsi = i2s(ikeys(i)).subsystems;
        for j = 1:length(subsi)
            ids{end + 1} = subsi{j}.identity;
        end
        identities{end + 1} = ids;
    end
    ikeys = ikeys';
end

function subs = compute_interfaces_for_subs(subs, model_path, subsystems_of_model)
    for j = 1:length(subsystems_of_model)
        if Subsystem.is_subsystem(subsystems_of_model(j))
            next_sub = Subsystem(subsystems_of_model(j), model_path);
            subs{end + 1} = next_sub;
        end
    end
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
        Helper.with_preserved_cfg(@close_system, model_path, 0);
    catch ME
        log(Helper.cfg().project_dir, 'log_close', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
    end
    bdclose all;
end

function log(project_dir, file_name, message)
    cd(project_dir)
    Helper.log(file_name, message);
end

function [old_path,models_evaluated,subs,modellist,models_mined] = startinit(needs_to_be_compilable)
    bdclose all;
    addpath(pwd)
    addpath(genpath('utils'), '-begin');
    set(0, 'DefaultFigureVisible', 'off');
    warning('off','all')
    
    old_path = path;
    disp("Starting mining process")
    Helper.cfg();
    Helper.cfg('reset');
    Helper.cfg('needs_to_be_compilable', needs_to_be_compilable);
    Helper.cfg('origin', pwd);
    Helper.reset_logs([Helper.cfg().interface2subs, Helper.cfg().name2subinfo_complete, Helper.cfg().name2subinfo, Helper.cfg().log_garbage_out, Helper.cfg().log_eval, Helper.cfg().log_close])
    models_evaluated = 0;
    subs = {};
    
    modellist = tdfread(Helper.cfg().modellist, '\t');

    if ~isfile(Helper.cfg().models_mined)
        mmID = fopen(Helper.cfg().models_mined, "w+");
        fprintf(mmID, "number,include\n");
        fclose(mmID);
    end
    models_mined = readtable(Helper.cfg().models_mined);
end