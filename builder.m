function builder()
    clean_up()
    name2interface_roots = Helper.parse_json(Helper.name2interface_roots);
    name2interface = Helper.parse_json(Helper.name2interface);
    interface2name = Helper.parse_json(Helper.interface2name_unique);


    name2mapping = dictionary(extractfield(name2interface, 'name'), extractfield(name2interface, 'mapping'));
    name2interface = dictionary(extractfield(name2interface, 'name'), extractfield(name2interface, 'ntrf'));
    interface2name = dictionary(extractfield(interface2name, 'ntrf'), extractfield(interface2name, 'names'));
    models = {};
    for i = 1:length(name2interface_roots)
        model = build_model(string(i), name2interface_roots(i), name2interface, name2mapping, interface2name);
        model = model.check_models_correctness();
        models{end + 1} = model;
    end
    disp(string(Helper.found_alt(0)) + " subsystems could have been changed")
end

function clean_up()
    warning('off','all')
    clear('all');
    delete(Helper.playground + filesep + "*");
    Helper.reset_logs([Helper.log_switch_up]);
end

function model = build_model(uuid, start_system, name2interface, name2mapping, interface2name)
    model = BuilderModel(uuid, start_system);
    model = model.switch_subs_in_model(name2interface, name2mapping, interface2name);
end