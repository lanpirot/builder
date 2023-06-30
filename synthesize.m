function synthesize()
    Helper.clean_up("Starting synthesis process", Helper.synthesize_playground, [Helper.log_synth_theory Helper.log_synth_practice])
    global name2subinfo
    name2subinfo = Helper.parse_json(Helper.name2subinfo);
    name2subinfo = Helper.build_sub_info(name2subinfo);
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
        [seed_model, model_root, root_metric] = seed_a_model();
        model = synth_repair(seed_model, model_root, root_metric, metric_target, Helper.max_repair_count);
        %build .slx model after 'model'
        %recompute metrics on .slx model
        if metrics_good(slx_model)
            %save slx_model
            good_models = good_models + 1;
        end
    end
end

function [model, root, root_metric] = seed_a_model()
    [model, root] = TheoryModel();
    root_metric = model.get_metric(Helper.target_metric);
end

function model = synth_repair(model, subsystem, subtree_curr, subtree_target, repairs_left)
    if subtree_curr == subtree_target
        return
    end
    %exchange current subsystem with a (hopefully) better one
    %run synth_repai on all children
    %compute new    subtree_curr
    bool = synth_repair(model, subsystem, subtree_curr, subtree_target, repairs_left - 1);
end


%For Helper.synth_num_elements: build homogenously. If target and x
%children, then each child has to be (0.75 * target - this_subs_elements)/children - (1.25*target - this_subs_elements)/children big.