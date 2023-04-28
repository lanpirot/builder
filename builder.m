function builder()
    clean_up()
    root_models = helper.parse(helper.root_interfaces);
    subsystems = helper.parse(helper.interfaces);
    eq_classes = helper.parse(helper.equivalence_classes_no_clones);


    eq_classes = dictionary(extractfield(eq_classes, 'hsh'), extractfield(eq_classes, 'subsystems'));
    models = {};
    for i = 1:length(root_models)
        model = build_model(string(i), root_models(i), eq_classes);
        model = model.check_models_correctness();
        models{end + 1} = model;
    end
end

function clean_up()
    delete(helper.playground + filesep + "*");
end

function model = build_model(uuid, start_system, eq_classes)
    model = BuilderModel(uuid, start_system);
    model = model.switch_subs_in_model(eq_classes);
end

function model = check_models_correctness(model)
    model = model.check_correctness();
end