function builder()
    clean_up()
    name2subinfo = Helper.parse_json(Helper.name2subinfo);
    model_root_identities = get_root_models(name2subinfo);

    sub_identities = extractfield(name2subinfo, Helper.identity);
    sub_info = build_sub_info(name2subinfo);

    name2subinfo = dictionary(sub_identities, sub_info);
    models = {};
    for i = 22:length(model_root_identities)
        disp("Rebuilding model " + string(i) + " of " + length(model_root_identities))
        models{end + 1} = build_model(string(i), model_root_identities{i}, name2subinfo);
    end
    disp(string(Helper.found_alt(0)) + " subsystems could have been changed")
end

function clean_up()
    warning('off','all')
    disp("Starting building process")
    clear('all');
    mkdir(Helper.playground)
    delete(Helper.playground + filesep + "*");
    Helper.reset_logs([Helper.log_switch_up Helper.log_construct Helper.log_compile Helper.log_copy_to_missing]);
end

function out = build_sub_info(name2subinfo)
    sub_identities = extractfield(name2subinfo, Helper.identity);
    %sub_hashes = {};
    %for i=1:length(sub_identities)
    %    sub_hashes{end + 1} = Identity(sub_identities{i}).hash();
    %end


    
    sub_interfaces = extractfield(name2subinfo, Helper.interface);
    sub_is_root = extractfield(name2subinfo, Helper.is_root);
    sub_depths = num2cell(extractfield(name2subinfo, Helper.sub_depth));
    subtree_depths = num2cell(extractfield(name2subinfo, Helper.subtree_depth));
    sub_diverseness = num2cell(extractfield(name2subinfo, Helper.diverseness));
    sub_num_contained_elements = num2cell(extractfield(name2subinfo, Helper.num_contained_elements));
    sub_info = [sub_identities; sub_interfaces; sub_is_root; sub_depths; subtree_depths; sub_diverseness; sub_num_contained_elements];
    sub_info = cell2struct(sub_info, {Helper.identity, Helper.interface, Helper.is_root, Helper.sub_depth, Helper.subtree_depth, Helper.diverseness, Helper.num_contained_elements});
    out = {};
    for i=1:length(sub_info)
        out{end + 1} = sub_info(i);
    end
end

function root_models = get_root_models(name2subinfo)
    root_models = {};
    for i=1:length(name2subinfo)
        if name2subinfo(i).(Helper.is_root)
            root_models{end + 1} = Identity(name2subinfo(i).(Helper.identity));
        end
    end
end

function model = build_model(uuid, root_model_identity, name2subinfo)
    model = ModelMutator(uuid, root_model_identity);
    if model.version >= 0 
        model = model.switch_subs_in_model(name2subinfo);
    end
end