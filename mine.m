function mine()
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
        
            if isnan(modellist.compilable(i)) || (needs_to_be_compilable && ~modellist.compilable(i)) || ~modellist.loadable(i) || ~modellist.closable(i)
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
    
        interface2ids = dic_int2subs(subs);
        report(interface2ids)
        serialize_id2subinfo(interface2ids, Helper.cfg().name2subinfo_complete, "Before");
        serialize_interface2id(interface2ids)


        deduplied_interface2ids = deduplify(interface2ids);
        report(deduplied_interface2ids)
        relax_on = needs_to_be_compilable && false;%activate relaxation here
        if relax_on
            relaxed_interface2ids = deduplify(relax(deduplied_interface2ids));
            report(relaxed_interface2ids)
        else
            relaxed_interface2ids = deduplied_interface2ids;
        end
        %serialize_id2subinfo(relaxed_interface2ids, Helper.cfg().name2subinfo, "After");
        %serialize_interface2id(relaxed_interface2ids)

        fprintf("\nFinished! %i models evaluated out of %i\n", models_evaluated, height(modellist.model_url))
        cleanup()
    end
end

function report(interface2subs)
    disp("========================================")
    disp("Interface Report")
    vals = interface2subs.values;

    lengths = arrayfun(@(x) length(x.subsystems), vals);
    [sortedLengths, sortIdx] = sort(lengths); % Get sorted indices
    sortedVals = wrev(vals(sortIdx));
    sortedLengths = wrev(sortedLengths);

    minLength = min(sortedLengths);
    maxLength = max(sortedLengths);
    medianLength = median(sortedLengths);
    averageLength = mean(sortedLengths);
    stdDevLength = std(sortedLengths);

    uniqueModelPathCounts = zeros(length(sortedVals), 1);
    % Loop over each element in vals
    for i = 1:length(sortedVals)
        % Extract all model_paths for the current val
        modelPaths = strings(1, length(sortedVals(i).subsystems));
        for j = 1:length(sortedVals(i).subsystems)
            % Append the model_path to the cell array
            modelPaths{j} = char(sortedVals(i).subsystems{j}.identity.model_path);
        end
        uniqueModelPathCounts(i) = length(unique(modelPaths));
    end    
    
    % Display results
    fprintf("[%s]\n", sprintf('%d,', sortedLengths))
    fprintf("[%s]\n", sprintf('%d,', uniqueModelPathCounts))
    fprintf("[%s]\n", sprintf('%s#', sortedVals.hash))


    fprintf('There are %i Equivalence Classes\n', length(lengths))
    fprintf('There are %i Singleton Equivalence Classes (%f)\n', sum(lengths == 1), sum(lengths == 1)/length(lengths))
    fprintf('Average Subsystem has %f substitution possibilities\n', sum(lengths .* (lengths - 1)) / sum(lengths))
    fprintf('Minimum Length: %d\n', minLength);
    fprintf('Maximum Length: %d\n', maxLength);
    fprintf('Median Length: %d\n', medianLength);
    fprintf('Average Length: %.2f\n', averageLength);
    fprintf('Standard Deviation: %.2f\n', stdDevLength);
    disp("========================================")
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

function interface2subs = dic_int2subs(subs)
    interface2subs  = configureDictionary("string", "Equivalence_class");
    for i = 1:length(subs)
        hash = subs{i}.interface.hash();
        if interface2subs.isKey(hash)
            eq = interface2subs(hash);
            eq = eq.add_subsystem(subs{i});
        else
            eq = Equivalence_class(subs{i}, hash);
        end
        interface2subs(hash) = eq;
    end
end

function relaxedi2ids = relax(interface2ids)    
    relaxedi2ids = configureDictionary("string","Equivalence_class");
    ikeys = interface2ids.keys();
    for i = 1:length(ikeys)
        relaxedi2ids(ikeys(i)) = Equivalence_class(interface2ids(ikeys(i)).subsystems, interface2ids(ikeys(i)).hash);
    end        

    %Variation Point: turn relax-number on/off, implement
    %"is_type_relaxed_equivalent", etc. for the if-clause
    for i = 1:length(ikeys)
        for j = 1:length(ikeys)
            if i ~= j && is_numbered_relaxed_equivalent(ikeys(i), ikeys(j)) % || is_type_relaxed_equivalent(ikeys(i), ikeys(j)) || is_dimension_relaxed_equivalent(ikeys(i), ikeys(j))
                relaxedi2ids(ikeys(j)).subsystems = unionize(relaxedi2ids(ikeys(i)), relaxedi2ids(ikeys(j)));
            end
        end
    end
end

function unioned = unionize(eq1, eq2)
    cellArray1 = eq1.subsystems;
    cellArray2 = eq2.subsystems;
    combined = [cellArray1, cellArray2];
    unioned = {};
    is_duplicate = false(1, length(combined));

    for i = 1:length(combined)
        if ~is_duplicate(i)
            unioned{end+1} = combined{i};
            for j = i+1:length(combined)
                if eq(combined{i}, combined{j})
                    is_duplicate(j) = true;
                end
            end
        end
    end
end


function bool = is_numbered_relaxed_equivalent(class1_hash, class2_hash)
    % Split the input strings by commas, preserving empty entries
    class1_in_out_special = strsplit(class1_hash, ',', 'CollapseDelimiters', false);
    class2_in_out_special = strsplit(class2_hash, ',', 'CollapseDelimiters', false);
    
    % Split the first elements by semicolons and check if sub is a subset of class
    sub_first = strsplit(class1_in_out_special{1}, ';', 'CollapseDelimiters', false);
    class_first = strsplit(class2_in_out_special{1}, ';', 'CollapseDelimiters', false);
    b1 = is_subsequence(sub_first, class_first);
    
    % Split the second elements by semicolons and check if class is a subset of sub
    sub_second = strsplit(class1_in_out_special{2}, ';', 'CollapseDelimiters', false);
    class_second = strsplit(class2_in_out_special{2}, ';', 'CollapseDelimiters', false);
    b2 = is_subsequence(class_second, sub_second);
    
    % Compare the third elements directly
    b3 = strcmp(class1_in_out_special{3}, class2_in_out_special{3});
    
    % Combine the results
    bool = b1 && b2 && b3;
end

function bool = is_subsequence(sub, super)
    i = 1;
    j = 1;
    while i <= length(sub)
        if ismember(sub(i), super(j:end))
            j = find(strcmp(super(j:end), sub(i)), 1) + j;
        else
            bool = false;
            return
        end
        i = i + 1;
    end
    bool = true;
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

function deduplified_interface2ids = deduplify(interface2ids)
    deduplified_interface2ids = configureDictionary("string", "Equivalence_class");
    ikeys = interface2ids.keys();
    for i = 1:length(ikeys)
        deduplified_interface2ids(ikeys(i)) = interface2ids(ikeys(i)).remove_duplicates();
    end
end

function serialize_interface2id(interface2id)
    [ikeys, identities] = make_i2s_smaller(interface2id);
    Helper.file_print(Helper.cfg().interface2subs, jsonencode({ikeys, identities}))
end

function serialize_id2subinfo(interface2ids, file_name, string_prefix)
    subinfo = {};
    ikeys = interface2ids.keys();

    for i = 1:length(ikeys)
        subinfo = [subinfo interface2ids(ikeys(i)).sort()];
    end
    Helper.file_print(file_name, jsonencode(subinfo));
    disp(string_prefix + " deleting duplicates, " + string(length(subinfo)) + " subsystems remain in " + string(length(ikeys)) + " interfaces.")
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

function cleanup()
    delete(Helper.cfg().models_mined)
    cd(Helper.cfg().origin)
end