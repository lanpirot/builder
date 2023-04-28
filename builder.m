function builder()
    clean_up()
    name2interface_roots = helper.parse_json(helper.name2interface_roots);
    name2interface = helper.parse_json(helper.name2interface);
    interface2name = helper.parse_json(helper.interface2name);

    name2interface = dictionary(extractfield(name2interface, 'name'), extractfield(name2interface, 'ntrf'));
    interface2name = dictionary(extractfield(interface2name, 'ntrf'), extractfield(interface2name, 'names'));
    models = {};
    for i = 1:length(name2interface_roots)
        model = build_model(string(i), name2interface_roots(i), name2interface, interface2name);
        model = model.check_models_correctness();
        models{end + 1} = model;
    end
end

function clean_up()
    delete(helper.playground + filesep + "*");
end

function model = build_model(uuid, start_system, name2interface, interface2name)
    model = BuilderModel(uuid, start_system);
    model = model.switch_subs_in_model(name2interface, interface2name);
end

function model = check_models_correctness(model)
    model = model.check_correctness();
end