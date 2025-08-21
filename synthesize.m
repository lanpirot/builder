function synthesize()
    Helper.clean_up("Starting synthesis process", Helper.synthesize_playground, [Helper.log_synth_theory Helper.log_synth_practice Helper.synth_report])
    global sy
    sy = struct();
    %Helper.profiles(profiles(chosen, dry, check, diverse, roots_only, compilable)
    Helper.profiles(Helper.synth_giant, 1, 0, 1, 1, 1)
    
    
    global name2subinfo_complete
    name2subinfo_complete = Helper.parse_json(Helper.name2subinfo_complete);
    name2subinfo_complete = Helper.build_sub_info(name2subinfo_complete);
    ks = name2subinfo_complete.keys();
    models = cell(1,length(ks));
    for i = 1:length(ks)
        n2i = name2subinfo_complete{ks(i)};
        n2i.sub_id = i;
        name2subinfo_complete{ks(i)} = n2i;
        models{i} = n2i.(Helper.identity).model_path;
    end
    models = unique(models);
    global model2id
    model2id = dictionary(models, 1:length(models));

    global interface2subs
    interface2subs = Helper.parse_json(Helper.interface2subs);
    interface2subs = dictionary(interface2subs{1}, interface2subs{2});
    start_synth_report()

    %only for a complete report about all snlnet models
    %slnet_report()
    %return
    
    bdclose all;
    tic
    [roots, models_synthed] = synth_rounds();
    disp("Total time building/saving " + toc)
    disp(".slx-synthesis file saved " + models_synthed + " times.")
    coverage_report(roots, models_synthed, length(models), length(ks))    
end

function slnet_report()
    global name2subinfo_complete

    roots = {};
    ks = name2subinfo_complete.keys();
    for i = 1:length(ks)
        if Identity(name2subinfo_complete{{ks{i}}}.IDENTITY).is_root()
            subtree = SubTree(name2subinfo_complete{{ks{i}}}.(Helper.identity), name2subinfo_complete);
            subtree = subtree.recursive_subtree(name2subinfo_complete);
            subtree = subtree.root_report();
            roots{end + 1} = subtree;
            Helper.log('synth_report', report2string(i, subtree));
        end
    end
    coverage_report(roots, length(roots), length(roots), length(name2subinfo_complete.keys()))
end

function coverage_report(roots, models_synthed, model_count, sub_count)
    start_synth_report();
    Helper.log('synth_report', "========END REPORT:=========");
    Helper.log('synth_report', "Total elapsed time: " + string(toc));

    % find first existing root to initialize copy array, then ....
    for i=1:length(roots)
        if isempty(roots{i})
            continue
        end
        roots_copy = struct(roots{i});
        break
    end

    % .... for all existing roots copy a struct of the roots
    for i = i+1:length(roots)
        if isempty(roots{i})
            continue
        end
        roots_copy(end + 1) = struct(roots{i});
    end
    roots = roots_copy;
    disp(string(length(roots)) + " models were created.")

    %size report
    Helper.log('synth_report', "Elements min_med_max_mean_stddev " + minmedmaxmedmeanstddev(horzcat(roots.num_elements)))
    Helper.log('synth_report', "Subsystems min_med_max_mean_stddev " + minmedmaxmedmeanstddev(horzcat(roots.num_subsystems)))
    Helper.log('synth_report', "Depths min_med_max_mean_stddev " + minmedmaxmedmeanstddev(horzcat(roots.local_depth)))   
    

    %how many models are covered
    all_models = horzcat(roots.unique_models);
    unique_models = unique(all_models);
    Helper.log('synth_report', "Ratio of models covered: " + string(length(unique_models) / model_count) + " (of " + model_count + " models)");
    %how many subsystems are covered
    all_subs = horzcat(roots.unique_subsystems);
    unique_subs = unique(all_subs);
    Helper.log('synth_report', "Ratio of subsystems covered: " + string(length(unique_subs)/sub_count) + " (of " + sub_count + " subsystems)")

    %what is the overlap between models
    overlap_ratios = struct;
    model_total_overlap = 0;
    subsystem_total_overlap = 0;
    for i = 1:length(roots)
        model_local_overlap_ratios = [];
        subsystem_local_overlap_ratios = [];
        for j = 1:length(roots)
            model_overlap = intersect(roots(i).unique_models, roots(j).unique_models);
            model_local_overlap_ratios(end + 1) = length(model_overlap) / length(roots(i).unique_models);
            if model_local_overlap_ratios(end) == 1
                model_total_overlap = model_total_overlap + 1;
            end

            subsystem_overlap = intersect(roots(i).unique_subsystems, roots(j).unique_subsystems);
            subsystem_local_overlap_ratios(end + 1) = length(subsystem_overlap) / length(roots(i).unique_subsystems);
            if subsystem_local_overlap_ratios(end) == 1
                subsystem_total_overlap = subsystem_total_overlap + 1;
            end
        end
        overlap_ratios(end + 1).model_mean = mean(model_local_overlap_ratios);
        overlap_ratios(end).model_median = median(model_local_overlap_ratios);
        overlap_ratios(end).subsystem_mean = mean(subsystem_local_overlap_ratios);
        overlap_ratios(end).subsystem_median = median(subsystem_local_overlap_ratios);
    end

    if models_synthed == 0
        models_synthed = length(roots);
    end
    model_means = vertcat(overlap_ratios.model_mean);
    model_medians = vertcat(overlap_ratios.model_median);
    Helper.log('synth_report', "Maximum of mean model overlaps: " + string(max(model_means)))
    Helper.log('synth_report', "Maximum of median model overlaps: " + string(max(model_medians)))
    Helper.log('synth_report', "In our set of " + string(models_synthed) + " models, we had " + model_total_overlap + " model overlaps (max: " + string(models_synthed^2) + ").")

    subsystem_means = vertcat(overlap_ratios.subsystem_mean);
    subsystem_medians = vertcat(overlap_ratios.subsystem_median);
    Helper.log('synth_report', "Maximum of mean subsystem overlaps: " + string(max(subsystem_means)))
    Helper.log('synth_report', "Maximum of median subsystem overlaps: " + string(max(subsystem_medians)))
    Helper.log('synth_report', "In our set of " + string(models_synthed) + " models, we had " + subsystem_total_overlap + " complete subsystem overlaps (max: " + string(models_synthed^2) + ").")
    Helper.log('synth_report', "========END REPORT END=========")
end

function out_string = minmedmaxmedmeanstddev(l)
    out_string = "";
    out_string = out_string + min(l) + ", ";
    out_string = out_string + median(l) + ", ";
    out_string = out_string + max(l) + ", ";
    out_string = out_string + mean(l) + ", ";
    out_string = out_string + std(l);
end

function [roots, good_models] = synth_rounds()
    global name2subinfo_complete model2id interface2subs depth_reached sy
    savename2subinfo_complete = name2subinfo_complete;
    savemodel2id = model2id;
    saveinterface2subs = interface2subs;
    
    good_models = 0;
    roots = {};
    for i = 1:sy.synth_model_count
        name2subinfo_complete = savename2subinfo_complete;
        model2id = savemodel2id;
        interface2subs = saveinterface2subs;
        rng(i, 'twister')
        depth_reached = 0;

        disp("Building model " + string(i))
        model_name = char("model" + string(i));
        model_path = Helper.synthesize_playground + filesep + model_name + ".slx";

        if Helper.is_synth_mode(Helper.synth_giant)
            while 1
                try
                    model_root = choose_subsystem([], Identity('', '', ''), 0).recursive_subtree(name2subinfo_complete).root_report();
                    break
                catch
                end
            end
            mutate_chances = sy.mutate_chances;
            while ~model_root.is_giant() && mutate_chances
                [model_root, mutation_performed] = model_root.mutate_bigger();
                fprintf("%i %i %i\n", model_root.local_depth, model_root.num_elements, model_root.num_subsystems);
                mutate_chances = mutate_chances - 1;
                if mutation_performed
                    mutate_chances = sy.mutate_chances;
                end
                %disp(report2string(i, model_root))
            end
            build_success = model_root.is_giant();
        else
            if Helper.is_synth_mode(Helper.synth_AST_model)
                tries_given = 1;
                while sy.mutate_chances > tries_given
                    while 1
                        try
                            AST_model = choose_subsystem([], Identity('', '', ''), 0).recursive_subtree(name2subinfo_complete);
                            break
                        catch
                        end
                    end
                    [model_root, build_success] = synth_repair([], Identity('', '', ''), 1, AST_model);
                    if build_success && model_root.recursive_same_AST(AST_model)
                        break
                    end
                    tries_given = tries_given + 1;
                end
            else
                [model_root, build_success] = synth_repair([], Identity('', '', ''), 1);
            end
        end
        
        
        if ~build_success
            disp("Building model " + string(i) + " FAILED")
            continue
        end
        model_root = model_root.root_report();
        roots{i} = model_root;
        Helper.log('synth_report', report2string(i, model_root));

        if sy.synth_dry_build
            continue
        end
        
        try
            disp("Saving model " + string(i) + " ...")
            [model_root, slx_handle, additional_level] = model_root.build_root(model_name);
            if additional_level
                model_root = model_root.add_level();
            end
            if sy.synth_double_check && ~slx_evaluate(slx_handle)
                dips("Error")
            end

            slx_save(slx_handle, model_path);

            good_models = good_models + 1;
            disp("Saved model " + string(i))
            if sy.synth_double_check
                load_system(model_path)
                model_root.is_discrepant_to_slx()
                close_system(model_path)
            end
        catch ME
            disp("Saving model " + string(i) + " FAILED")
            Helper.log('log_synth_practice', ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line + ", Model-no: " + string(i))
        end
        delete(Helper.synthesize_playground + filesep + "*.slmx");
    end
end

function [subtree, build_success] = synth_repair(interface, not_identity, depth, AST_model)
    global name2subinfo_complete sy
    subtree = [];
    build_success = 0;

    if stop_repairing(depth)
        return
    end
    
    for i = 1:sy.synth_repair_count
        %choose identity fitting to interface and not_identity
        if Helper.is_synth_mode(Helper.synth_AST_model)
            subtree = choose_subsystem(interface, not_identity, depth, length(AST_model.children));
        else
            subtree = choose_subsystem(interface, not_identity, depth);
        end
        if isempty(subtree)
            continue
        end

        children_before = subtree.children;
        subtree.children = [];
        sub_met = 1;
        %run synth_repair on all children
        for j = 1:length(children_before)
            try
                child_before = name2subinfo_complete{{children_before(j)}};
                if Helper.is_synth_mode(Helper.synth_AST_model)
                    [child_after, sub_met] = synth_repair(child_before.(Helper.interface).hsh, subtree.identity, depth + 1, AST_model.children{j});
                else
                    [child_after, sub_met] = synth_repair(child_before.(Helper.interface).hsh, subtree.identity, depth + 1);
                end
                if ~sub_met
                    break
                end
                subtree.children{j} = child_after;
            catch
                sub_met = 0;
                break
            end
        end
        if isempty(children_before) || (j == length(children_before) && sub_met)
            build_success = 1;
            return
        end
    end
end

function stop = stop_repairing(depth)
    global sy
    stop = 0;
    switch sy.synth_mode
        case Helper.synth_AST_model
            return
        case Helper.synth_depth
            global depth_reached
            if depth > sy.synth_max_depth
                depth_reached = 1;
            end
            return
        otherwise
            if depth > sy.synth_max_depth
                stop = 1;
            end
    end    
end

function str = report2string(model_no, root)
    str = string(model_no) + "," + root.local_depth + "," + root.num_elements + "," + root.num_subsystems + "," + length(root.unique_models) + "," + length(root.unique_subsystems);
end

function bool = slx_evaluate(slx_identity)
    bool = loadable(slx_identity);%&& (~sy.needs_to_be_compilable || compilable(slx_identity))
end

function start_synth_report()
    global sy
    Helper.log('synth_report', ",,,,synth_model_count " + string(sy.synth_model_count + " synth_repair_count " + sy.synth_repair_count + " synth_max_depth " + sy.synth_max_depth + " synth_mode " + sy.synth_mode) + " synth_force_diversity " + sy.synth_force_diversity)
    Helper.log('synth_report', "model_no, depth, elements, subs, unique_models, unique_subsystems");
end

function bool = loadable(slx_identity)
    global sy
    try
        load_system(slx_identity)
        if ~sy.needs_to_be_compilable || compilable(slx_identity)
            bool = 1;
        end        
    catch
        bool = 0;
    end
end

function slx_save(slx_handle, model_path)    
    save_system(slx_handle, model_path)
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