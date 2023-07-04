function synthesize()
    Helper.clean_up("Starting synthesis process", Helper.synthesize_playground, [Helper.log_synth_theory Helper.log_synth_practice])
    global name2subinfo
    name2subinfo = Helper.parse_json(Helper.name2subinfo_chimerable);
    name2subinfo = Helper.build_sub_info(name2subinfo);
    global interface2subs
    interface2subs = Helper.parse_json(Helper.interface2subs);
    interface2subs = dictionary(interface2subs{1}, interface2subs{2});


    rounds = 0;
    success = 1;
    while success
        metric_target = 2 ^ rounds;
        rounds = rounds + 1;
        if strcmp(Helper.target_metric, Helper.synth_model_sub_tree)
            disp("Trying to synth model no. " + string(rounds))
        else
            disp("Synthing with target of " + string(metric_target) + " for metric " + Helper.target_metric)
        end
        models_synthed = synth_rounds(metric_target);
        success = models_synthed > Helper.target_model_count * Helper.target_count_min_ratio;
        disp("Synthesis was successful " + models_synthed + " times.")
    end
    disp("Finished synthesis attempts.")
end

function good_models = synth_rounds(metric_target)
    %if strcmp(Helper.target_metric, Helper.synth_model_sub_tree) parse random model's subtree and set as goal subtree
    good_models = 0;
    for i = 1:Helper.target_model_count
        start_interface = seed_interface();
        [model_root, metric_met] = synth_repair(start_interface, Identity("", "", ""), metric_target);
        if ~metric_met
            continue
        end
        slx_identity = model_root.build();
        if slx_evaluate(slx_identity)
            %save slx_model
            good_models = good_models + 1;
        end
    end
end

function interface = seed_interface()
    global name2subinfo
    nkeys = name2subinfo.keys();
    interface = name2subinfo{choose_random(nkeys)}.(Helper.interface).hsh;
end

function [subtree, local_metric, metric_met] = synth_repair(interface, not_identity, metric_target)
    for i = 1:Helper.max_repair_count
        %choose identity fitting to interface and not_identity
        subtree = choose_subsystem(interface, not_identity, metric_target);
        curr_metric_target = subtree.adapt_target(curr_metric_target);
        
        %run synth_repair on all children
        for j = 1:length(subtree.children)
            [subtree.children(i) sub_metric, sub_met] = synth_repair(interface2sub(subtree.children(i).interface.hash()), subtree.identity, curr_metric_target);
            if ~sub_met
                subtree.children(i) = [];
                break
            end
        end
        
        [metric_met, local_metric] = evaluate_subtree(subtree, metric_target);
        if metric_met
            return
        end
    end
end

function subsystem = choose_subsystem(interface, not_identity, metric_target)
    %collect suitable subsystems
    subsystems = interface2subs(interface);
    %remove those, which are excluded because of not_identity
    subsystems = remove_not_identity(subsystems, not_identity);
    switch Helper.target_metric
        case Helper.synth_random
            subsystem = choose_random(subsystems);
    end
end

function bool = evaluate_subtree(subtree, target)
    switch Helper.target_metric
        case Helper.synth_random
            bool = 1;
    end
end

function element = choose_random(array)
    element = array(randi(length(array)));
end