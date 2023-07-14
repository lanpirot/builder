function synthesize()

    Helper.clean_up("Starting synthesis process", Helper.synthesize_playground, [Helper.log_synth_theory Helper.log_synth_practice Helper.synth_report])
    global name2subinfo
    name2subinfo = Helper.parse_json(Helper.name2subinfo_chimerable);
    name2subinfo = Helper.build_sub_info(name2subinfo);
    global name2subinfo_complete
    name2subinfo_complete = Helper.parse_json(Helper.name2subinfo_complete);
    name2subinfo_complete = Helper.build_sub_info(name2subinfo_complete);
    global interface2subs
    interface2subs = Helper.parse_json(Helper.interface2subs);
    interface2subs = dictionary(interface2subs{1}, interface2subs{2});
    start_synth_report()

    
    rounds = 0;
    success = 1;
    while success
        metric_target = compute_target(rounds);
        rounds = rounds + 1;
        if strcmp(Helper.synth_target_metric, Helper.synth_model_sub_tree)
            disp("Trying to synth model no. " + string(rounds))
        else
            disp("Synthing with target of " + string(metric_target) + " for metric " + Helper.synth_target_metric)
        end
        models_synthed = synth_rounds(metric_target);
        success = models_synthed >= Helper.target_model_count * Helper.target_count_min_ratio;
        disp("Synthesis was successful " + models_synthed + " times.")
    end
    disp("Finished synthesis attempts.")
end

function good_models = synth_rounds(metric_target)
    %if strcmp(Helper.synth_target_metric, Helper.synth_model_sub_tree) parse random model's subtree and set as goal subtree
    
    good_models = 0;
    for i = 2%1:Helper.target_model_count
        rng(i)
        disp("Building model " + string(i))
        start_interface = seed_interface();
        [model_root, ~, metric_met] = synth_repair(start_interface, Identity("", "", ""), metric_target, 1);              %if random models are too small or big: choose root subsystem as base
        if ~metric_met
            disp("Building model " + string(i) + " FAILED")
            continue
        end
        [theory_report, model_root] = model_root.root_report();
        practice_report = dummy_report();
        disp("Saving model " + string(i))
        try
            [slx_handle, additional_level] = model_root.build_root();
            if additional_level
                theory_report = add_level(theory_report);
            end
            if slx_evaluate(slx_handle)
               practice_report = basic_slx_report(slx_handle);
               slx_save(slx_handle, i);
               good_models = good_models + 1;
               disp("Saved model " + string(i))
            else
                disp("Saving model " + string(i) + " FAILED")
            end
        catch ME
            disp("Saving model " + string(i) + " FAILED")
            Helper.log('log_synth_practice', ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line)
        end
        Helper.log('synth_report', report2string(i, theory_report, practice_report));
        delete(Helper.synthesize_playground + filesep + "*.slmx");
    end
end

function report = add_level(report)
    report.(Helper.local_depth) = report.(Helper.local_depth) + 1;
    report.(Helper.num_local_elements) = report.(Helper.num_local_elements) + 1;
    report.(Helper.num_subsystems) = report.(Helper.num_subsystems) + 1;
end

function report = dummy_report()
    report = struct();
    report.(Helper.local_depth) = "";
    report.(Helper.num_local_elements) = "";
    report.(Helper.num_subsystems) = "";
end

function str = report2string(model_no, theory_report, practice_report)
    str = string(model_no) + "," + theory_report.(Helper.local_depth) + "," + theory_report.(Helper.num_local_elements) + "," + theory_report.(Helper.num_subsystems) + "," + theory_report.(Helper.unique_models) + "," + practice_report.(Helper.local_depth) + "," + practice_report.(Helper.num_local_elements) + "," + practice_report.(Helper.num_subsystems);
end

function report = basic_slx_report(handle)
    report = struct;
    all_subsystems = Helper.get_contained_subsystems(handle, 1000);
    max_depth = 0;
    for i = 1:length(all_subsystems)
        max_depth = max(max_depth, Helper.get_depth(all_subsystems(i)));
    end
    report.(Helper.local_depth) = max_depth;
    report.(Helper.num_local_elements) = length(Helper.find_elements(handle));
    report.(Helper.num_subsystems) = length(all_subsystems) + 1;
end

function interface = seed_interface()
    global name2subinfo
    nkeys = name2subinfo.keys();
    interface = name2subinfo{choose_random(nkeys)}.(Helper.interface).hsh;
end

function [subtree, curr_metric_target, metric_met] = synth_repair(interface, not_identity, metric_target, depth)
    subtree = [];
    curr_metric_target = -1;
    metric_met = 0;

    if depth > Helper.synth_max_depth
        return
    end
    global name2subinfo_complete
    for i = 1:Helper.max_repair_count
        curr_metric_target = metric_target;
        %choose identity fitting to interface and not_identity
        subtree = choose_subsystem(interface, not_identity, curr_metric_target);
        if isempty(subtree)
            continue
        end
        curr_metric_target = subtree.adapt_target_local(curr_metric_target);


        children_before = subtree.children;
        subtree.children = [];
        sub_met = 1;
        %run synth_repair on all children
        for j = 1:length(children_before)
            child_before = name2subinfo_complete{{children_before(j)}};
            [child_after, sub_metric, sub_met] = synth_repair(child_before.(Helper.interface).hsh, subtree.identity, curr_metric_target, depth + 1);
            if ~sub_met
                break
            end
            subtree.children{j} = child_after;
            curr_metric_target = subtree.adapt_target_descendants(sub_metric, curr_metric_target);
        end
        if sub_met
            metric_met = subtree.is_metric_met(curr_metric_target, metric_target);
            if metric_met
                return
            end
        end
    end
end

function subsystem = choose_subsystem(interface, not_identity, metric_target)
    global name2subinfo
    global interface2subs
    %collect suitable subsystems
    subsystems = interface2subs{{interface}};
    %remove those, which are excluded because of not_identity
    %subsystems = remove_not_identity(subsystems, not_identity);
    if isempty(subsystems)
        subsystem = [];
        return
    end

    switch Helper.synth_target_metric
        case Helper.synth_random
            subsystem = SubTree(choose_random(subsystems), name2subinfo);
    end
end

function subsystems = remove_not_identity(subsystems, not_identity)
    for i = 1:length(subsystems)
        if strcmp(subsystems(i).model_path, not_identity.model_path)
            subsystems = [subsystems(1:i-1); subsystems(i+1:end)];
            return
        end
    end
end

function bool = evaluate_subtree(subtree, target)
    switch Helper.synth_target_metric
        case Helper.synth_random
            bool = 1;
    end
end

function target = compute_target(rounds)
    switch Helper.synth_target_metric
        case Helper.synth_depth
            target = rounds;
        case Helper.synth_num_elements
            target = 2^rounds;
        otherwise
            target = -1;
    end
end

function element = choose_random(array)
    element = array(randi(length(array)));
end

function bool = slx_evaluate(slx_identity)
    bool = loadable(slx_identity) && slx_metrics_met(slx_identity);%&& (~Helper.needs_to_be_compilable || compilable(slx_identity))
end

function bool = slx_metrics_met(slx_identity, metric_target)
    switch Helper.synth_target_metric
        case Helper.synth_random
            bool = 1;
    end
end

function start_synth_report()
    Helper.log('synth_report', ",,,,,,,target_model_count " + string(Helper.target_model_count + " max_repair_count " + Helper.max_repair_count + " synth_max_depth " + Helper.synth_max_depth + " synth_target_metric " + Helper.synth_target_metric))
    Helper.log('synth_report', "model_no, depth, elements, subs, unique, depth, elements, subs");
end

function bool = loadable(slx_identity)
    try
        load_system(slx_identity)
        if ~Helper.needs_to_be_compilable || compilable(slx_identity)
            bool = 1;
        end        
    catch
        bool = 0;
    end
end

function slx_save(slx_handle, model_no)
    save_system(slx_handle, Helper.synthesize_playground + filesep + "model" + string(model_no))
    close_system(slx_handle)
end

function cp = compilable(model_name)
    Helper.create_garbage_dir()
    try
        eval([model_name, '([],[],[],''compile'');']);
        cp = 1;
        try
            while 1
                eval([model_name, '([],[],[],''term'');']);
            end
        catch
        end
    catch ME
        if contains(pwd, "tmp_garbage")
            cd("..")
        end
        Helper.log('log_compile', string(jsonencode(slx_identity)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line)
        cp = 0;
    end
    if contains(pwd, "tmp_garbage")
        cd("..")
    end
    Helper.clear_garbage();
end