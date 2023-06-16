function builder()
    clean_up()
    name2subinfo_roots = Helper.parse_json(Helper.name2subinfo_roots);
    name2subinfo = Helper.parse_json(Helper.name2subinfo);
    interface2name = Helper.parse_json(Helper.interface2name_unique);

    sub_names = extractfield(name2subinfo, Helper.name);
    sub_info = build_sub_info(name2subinfo);

    name2subinfo = dictionary(sub_names, sub_info);
    interface2name = dictionary(extractfield(interface2name, Helper.ntrf), extractfield(interface2name, Helper.names));
    models = {};
    for i = 1:length(name2subinfo_roots)
        disp("Rebuilding model " + string(i) + " of " + length(name2subinfo_roots))
        model = build_model(string(i), name2subinfo_roots(i), name2subinfo, interface2name);
        models{end + 1} = model;
    end
    disp(string(Helper.found_alt(0)) + " subsystems could have been changed")
end

function out = build_sub_info(name2subinfo)
    sub_names = extractfield(name2subinfo, Helper.name);
    sub_mappings = extractfield(name2subinfo, Helper.mapping);
    sub_ntrfs = extractfield(name2subinfo, Helper.ntrf);
    sub_depths = num2cell(extractfield(name2subinfo, Helper.depth));
    sub_divers = num2cell(extractfield(name2subinfo, Helper.diverseness));
    sub_info = [sub_names; sub_mappings; sub_ntrfs; sub_depths; sub_divers];
    sub_info = cell2struct(sub_info, {Helper.name, Helper.mapping, Helper.ntrf, Helper.depth, Helper.diverseness});
    out = {};
    for i=1:length(sub_info)
        out{end + 1} = sub_info(i);
    end
end

function clean_up()
    warning('off','all')
    disp("Starting building process")
    clear('all');
    mkdir(Helper.playground)
    delete(Helper.playground + filesep + "*");
    Helper.reset_logs([Helper.log_switch_up]);
end

function model = build_model(uuid, start_system, name2subinfo, interface2name)
    model = ModelBuilder(uuid, start_system);
    if model.version >= 0 
        model = model.switch_subs_in_model(name2subinfo, interface2name);
    end
end