function subsystem = choose_subsystem(interface, not_identity, depth, AST_children_count)
    global name2subinfo_complete interface2subs synth

    subsystem = [];

    for i = 1:synth.choose_retries
        if depth <= 1
            if Helper.is_synth_mode(Helper.synth_AST_model) && depth == 1
                interface = seed_interface(AST_children_count);
            else
                interface = seed_interface();
            end
        end
        %collect suitable subsystems
        if ~any(find(strcmp(interface2subs.keys(), interface)))
            continue
        end
        subsystems = interface2subs{{interface}};
    
        switch synth.mode
            case Helper.synth_random
                subsystem = SubTree(choose_random(subsystems), name2subinfo_complete);
            case Helper.synth_width
                subsystem = sample_and_choose(depth, subsystems, Helper.children);
            case Helper.synth_depth
                subsystem = sample_and_choose(depth, subsystems, Helper.subtree_depth);
            case Helper.synth_AST_model
                if depth >= 1
                    subsystem = pick_first(subsystems, AST_children_count);
                else
                    subsystem = SubTree(choose_random(subsystems), name2subinfo_complete);
                end
            case Helper.synth_giant
                if rand < 0.1 && depth < synth.max_depth / 2
                    subsystem = sample_and_choose(depth, subsystems, Helper.subtree_depth);
                else
                    subsystem = sample_and_choose(depth, subsystems, Helper.children);
                end
        end
        if isempty(subsystem) || (synth.force_diversity && strcmp(not_identity.model_path, subsystem.identity.model_path))
            continue
        end

        if depth > 1 || ~synth.seed_with_roots_only || Identity(name2subinfo_complete{{struct(subsystem.identity)}}.IDENTITY).is_root()
            return
        end
    end
end

function interface = seed_interface(AST_children_count)
    global name2subinfo_complete synth
    nkeys = name2subinfo_complete.keys();
    while 1
        chosen_key = choose_random(nkeys);
        if ~synth.seed_with_roots_only || Identity(name2subinfo_complete{chosen_key}.IDENTITY).is_root()
            interface = name2subinfo_complete{chosen_key}.(Helper.interface).hsh;
            if Helper.is_synth_mode(Helper.synth_AST_model)
                if ~exist("AST_children_count", 'var') || length(name2subinfo_complete{chosen_key}.(Helper.children)) == AST_children_count
                    return
                end
            else 
                return
            end
        end
    end
end

function subsystem = pick_first(subsystems, children_count)
    global name2subinfo_complete
    subsystem = [];
    for i = 1:min(length(subsystems), 10*log(length(subsystems)))
        j = randi(length(subsystems));
        if length(name2subinfo_complete{{subsystems(j)}}.(Helper.children)) == children_count
            subsystem = SubTree(subsystems(j), name2subinfo_complete);
            return
        end
    end
end

function subsystem = sample_and_choose(depth, subsystems, property)
    global name2subinfo_complete depth_reached synth
    sample_size = min(length(subsystems), randi(synth.choose_sample_size));
    for i = 1:sample_size
        if strcmp(synth.model_count, Helper.synth_giant) && mod(i,2)
            alt_choice = name2subinfo_complete{{subsystems(max(1,end-i))}};
        else
            alt_choice = name2subinfo_complete{{choose_random(subsystems)}};
        end
        alt_choice_num = alt_choice.(property);
        if isempty(alt_choice_num) || isstruct(alt_choice_num)
            alt_choice_num = length(alt_choice_num);
        end
        if i == 1 || choice_num < alt_choice_num && (depth < synth.max_depth) && (~strcmp(synth.mode, Helper.synth_depth) || depth_reached == 0) || choice_num > alt_choice_num  && (depth >= synth.max_depth || depth_reached == 1)
            choice = alt_choice;
            choice_num = alt_choice_num;
        end
    end

    subsystem = SubTree(choice.IDENTITY, name2subinfo_complete);
    return
end

function element = choose_random(array)
    element = array(randi(length(array)));
end