function builder()
    clean_up()
    root_models = helper.parse_interfaces(helper.root_interfaces);
    subsystems = helper.parse_interfaces(helper.interfaces);
    models = {};
    for i = 1:length(root_models)
        model = build_model(string(i), root_models(i));
        model = model.check_models_correctness();
        models{end + 1} = model;
    end
end

function clean_up()
    delete(helper.playground + filesep + "*");
end

function model = build_model(uuid, start_system)
    model = BuilderModel(uuid, start_system);
    model = model.switch_up();
end

function model = check_models_correctness(model)
    model = model.check_correctness();
end