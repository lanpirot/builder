function mine(max_number_of_models)
    addpath(pwd)
    addpath(genpath('utils'), '-begin');
    set(0, 'DefaultFigureVisible', 'off');
    warning('off','all')

    old_path = path;
    disp("Starting mining process")
    Helper.reset_logs([Helper.name2subinfo, Helper.name2subinfo_chimerable, Helper.interface2subs, Helper.name2subinfo_complete, Helper.log_garbage_out, Helper.log_eval, Helper.log_close])
    models_evaluated = 0;
    subs = {};
    project_dir = Helper.project_dir;
    needs_to_be_compilable = Helper.needs_to_be_compilable;

    modellist = tdfread(Helper.modellist, 'tab');
    if ~exist("max_number_of_models",'var')
        max_number_of_models = height(modellist.model_url);
    end
    for i = 1:100 % max_number_of_models
        path(old_path);
    
        if (needs_to_be_compilable && ~modellist.compilable(i)) || ~modellist.loadable(i)
            continue
        end
        Helper.create_garbage_dir();
        model_path = string(strip(modellist.model_url(i, :), "right"));

        try
            model_handle = load_system(model_path);
            model_name = get_param(model_handle, 'Name');
            try
                set_param(model_name, 'SimMechanicsOpenEditorOnUpdate', 'off')
            catch
            end

            if model_is_problem_file(model_name)
                errar("")
            end

            try 
                systemcomposer.loadModel(model_name);%skip architecture models
                cd(project_dir)
                close(model_name)
                try_close(model_name, model_path)                
                continue
            catch
            end

            if needs_to_be_compilable
                eval([model_name, '([],[],[],''compile'');']);
            end
            cd(project_dir)
            disp("Mining interfaces of model no. " + string(i) + " " + model_path)
            subs = compute_interfaces_for_subs(subs, model_handle, model_path);

            if needs_to_be_compilable
                try_end(model_name);
            end
            try_close(model_name, model_path);
            models_evaluated = models_evaluated + 1;
        catch ME
            cd(project_dir)
            log(project_dir, 'log_eval', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            try_close(model_name, model_path);
        end
        cd(project_dir)
        Helper.clear_garbage()
        close all force;
    end
    disp("We analyzed " + string(length(subs)) + " Subsystems altogether.")
    subs = remove_skips(subs);
    disp(string(length(subs)) + " Subsystems were taken into account (no bus ports present etc.).")


    %FIRST: complete dictionary containing all subs
    interface2subs = dic_int2subs(subs, 0);
    serialize(interface2subs, -1);

    %THEN: dictionary only for unique subsystems
    interface2subs = dic_int2subs(subs, 1);
    serialize(interface2subs, 0);
    %identity2sub = dic_id2sub(subs); not needed anymore?
    fprintf("\nFinished! %i models evaluated out of %i\n", models_evaluated, height(modellist.model_url))
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

function interface2subs = dic_int2subs(subs, remove_duplicates)
    interface2subs  = dictionary();
    for i = 1:length(subs)
        hash = subs{i}.interface.hash();
        if isConfigured(interface2subs) && interface2subs.isKey(hash)
            eq = interface2subs(hash);
            eq = eq.add_subsystem(subs{i}, remove_duplicates);
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

function serialize(interface2subs, outputmode)
    %serialize sub_info
    subinfo = {};
    ikeys = interface2subs.keys();
    for i = 1:length(ikeys)
        subinfo = [subinfo interface2subs(ikeys(i)).less_fields().subsystems];
    end

    string_prefix = "After";
    switch outputmode
        case -1
            Helper.file_print(Helper.name2subinfo_complete, jsonencode(subinfo));
            [ikeys, identities] = make_i2s_smaller(interface2subs);
            Helper.file_print(Helper.interface2subs, jsonencode({ikeys, identities}))
            string_prefix = "Before";
        case 0
            Helper.file_print(Helper.name2subinfo, jsonencode(subinfo));
            [ikeys, identities] = make_i2s_smaller(interface2subs);
            Helper.file_print(Helper.interface2subs, jsonencode({ikeys, identities}))
    end

    disp(string_prefix + " deleting duplicates, " + string(length(subinfo)) + " subsystems remain in " + string(length(keys(interface2subs))) + " interfaces.")
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

function subs = compute_interfaces_for_subs(subs, model_handle, model_path)
    subsystems = Helper.find_subsystems(model_handle);
    subsystems(end + 1) = model_handle;%the root subsystem
    for j = 1:length(subsystems)
        if Subsystem.is_subsystem(subsystems(j))
            next_sub = Subsystem(subsystems(j), model_path);
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
        bdclose all;
        close_system(model_path)
    catch ME
        log(Helper.project_dir, 'log_close', model_path + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
    end
end

function log(project_dir, file_name, message)
    cd(project_dir)
    Helper.log(file_name, message);
end