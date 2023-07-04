function mutate()
    Helper.clean_up("Starting building process", Helper.mutate_playground, [Helper.log_switch_up Helper.log_compile Helper.log_copy_to_missing])
    name2subinfo = Helper.parse_json(Helper.name2subinfo);
    model_root_identities = get_root_models(name2subinfo);
    name2subinfo = Helper.build_sub_info(name2subinfo);

    
    models = {};
    for i = 1:length(model_root_identities)
        disp("Rebuilding model " + string(i) + " of " + length(model_root_identities))
        models{end + 1} = build_model(string(i), model_root_identities{i}, name2subinfo);
    end
    disp(string(Helper.found_alt(0)) + " subsystems could have been changed")
end

function root_models = get_root_models(name2subinfo)
    root_models = {};
    for i=1:length(name2subinfo)
        identity = Identity(name2subinfo(i).(Helper.identity));
        if identity.is_root()
            root_models{end + 1} = identity;
        end
    end
end

function model = build_model(uuid, root_model_identity, name2subinfo)
    model = ModelMutator(uuid, root_model_identity);
    if model.version >= 0 
        model = model.switch_subs_in_model(name2subinfo);
    end
end