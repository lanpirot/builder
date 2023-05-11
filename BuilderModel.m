classdef BuilderModel
    properties
        uuid
        version = 0;
        original_model_name
        original_model_path
        model_name
        root_model_path

        num_original_subsystems
        num_switched_subsystems

        built_correct
    end
    
    methods
        function obj = BuilderModel(uuid, root_model)
            obj.uuid = uuid;
            tmp = split(root_model.name, Helper.second_level_divider);
            obj.original_model_name = string(tmp{end});
            obj.original_model_path = tmp{1};

            obj = obj.copy_version();

            load_system(obj.root_model_path)
            obj.num_original_subsystems = length(Subsystem.get_contained_subsystems(get_param(obj.model_name, 'Handle')));
            close_system(obj.root_model_path, 0)
        end

        function obj = save_version(obj)
            obj.version = obj.version + 1;
            new_suffix = "v" + string(obj.version);
            save_system(obj.model_name, extractBefore(obj.root_model_path, strlength(obj.root_model_path)-3) + new_suffix + extractAfter(obj.root_model_path, strlength(obj.root_model_path)-4))
            close_system(obj.model_name + new_suffix)
            load_system(obj.root_model_path)
        end

        function obj = copy_version(obj)            
            obj.model_name = "model" + string(obj.uuid);
            obj.root_model_path = Helper.playground + filesep + obj.model_name + extractAfter(obj.original_model_path,strlength(obj.original_model_path)-4);
            copyfile(obj.original_model_path, obj.root_model_path);
        end

        function obj = switch_subs_in_model(obj, name2interface, name2mapping, interface2name)
            %try
                load_system(obj.root_model_path);
                
                curr_depth = 0;
                while 1
                    sub_at_depth_found = 0;
                    sub_names = Helper.find_subsystems(obj.model_name);
                    sub_names{end + 1} = char(obj.model_name);
                    for i = 1:length(sub_names)
                        sub_name = sub_names{i};
                        if curr_depth == 0 && Subsystem.is_root_static(sub_name) || count(get_param(sub_name, 'Parent'), "/") == curr_depth - 1 && Subsystem.is_subsystem(sub_name) && ~Subsystem.is_root_static(sub_name)
                            sub_at_depth_found = 1;
                            obj = obj.switch_sub(obj.model_name, sub_name, name2interface, name2mapping, interface2name);
                        end
                    end
                    if ~sub_at_depth_found
                        break;
                    end
                    curr_depth = curr_depth + 1;
                end
                close_system(obj.root_model_path, 0);
            %catch ME
                %Helper.log('log_switch_up', string(jsonencode(obj)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                %throw(ME) 
            %end
            delete(obj.root_model_path)
        end

        function obj = switch_sub(obj, model_name, sub_name, name2interface, name2mapping, interface2name)
            qualified_name = Helper.get_qualified_name_from_handle(obj.original_model_name, sub_name);
            sub_complete_name = Helper.name_hash(obj.original_model_path, qualified_name);
            sub_interface = name2interface({char(sub_complete_name)});
            alt_complete_names = interface2name(sub_interface);
            alt_complete_names = alt_complete_names{1};

            if length(alt_complete_names) > 1
                while 1
                    rindex = randi(length(alt_complete_names));
                    if ~strcmp(sub_complete_name, alt_complete_names{rindex})
                        sub_mapping = name2mapping({char(sub_complete_name)});
                        alt_mapping = name2mapping({char(alt_complete_names{rindex})});
                        try
                            obj = obj.switch_sub_with_sub(model_name, sub_name, alt_complete_names{rindex}, sub_mapping, alt_mapping);
                            obj = obj.save_version();
                        catch ME
                            Helper.log('log_switch_up', string(jsonencode(obj)) + newline + alt_complete_names{rindex} + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                        end
                        break
                    end
                end
            end
        end

        function obj = switch_sub_with_sub(obj, model_name, sub_name, alternate_sub_name, sub_mapping, alt_mapping)

            [alt_model_path, alt_sub_qualified_name] = Helper.unfuse_hash(alternate_sub_name);
            switch_model_handle = load_system(alt_model_path);
            load_system(alt_sub_qualified_name)
            switch_sub_handle = get_param(alt_sub_qualified_name, 'Handle');

            % 
            % 
            copy_from = SimulinkName(Helper.get_qualified_name_from_handle(get_param(switch_model_handle, 'Name'), switch_sub_handle), get_param(switch_model_handle, 'Name'));
            copy_to = SimulinkName(Helper.get_qualified_name_from_handle(get_param(model_name, 'Name'), sub_name), obj.original_model_name);

            copied_name = SimulinkName(join([copy_to.ancestor_names "sub" + string(Helper.found_alt(1))], "/"), obj.original_model_name);
            if copy_to.is_root
                
                if copy_from.is_root
                    %copy from root to root
                    close_system(obj.model_name)
                    delete(obj.root_model_path)
                    copyfile(alt_model_path, obj.root_model_path);
                    load_system(obj.root_model_path);
                else
                    %copy from subsystem to root
                    Simulink.BlockDiagram.deleteContents(copy_to.full_name)
                    Simulink.SubSystem.copyContentsToBlockDiagram(copy_from.full_name, copy_to.full_name)
                end
                %we don't need to rewire the inputs/outputs after copying
            else
                if copy_from.is_root
                    %copy from root to subsystem
                    Simulink.BlockDiagram.createSubsystem(get_param(sub_name, 'Handle'), 'Name', copied_name.element_name)
                    Simulink.SubSystem.deleteContents(copied_name.full_name)
                    Simulink.BlockDiagram.copyContentsToSubsystem(copy_from.full_name, copied_name.full_name)
                    set_param(copied_name.full_name, 'Name', copy_to.element_name)
                else
                    %copy from subsystem to subsystem
                    delete_block(copy_to.full_name)
                    add_block(copy_from.full_name, copy_to.full_name)
                end
                %now, rewire
                %inports = get_ports_of_sub(copy_to.full_name, 'Inports')
                %^^^^^^ handles of other elements/signals connected to each port
                %rewire first inport: 
                %outports = get_ports_of_sub(copy_to.full_name, 'Outports')
            end
            annotation_text = "Copied system from: " + alternate_sub_name + newline + " into: " + Helper.name_hash(obj.original_model_path, copy_to.original_full_name);
            a = Simulink.Annotation(copy_to.full_name,annotation_text);
            a.FontSize = 18;
            a.BackgroundColor = 'lightBlue';
            disp(annotation_text)
        end

        function obj = check_models_correctness(obj)
            obj.built_correct = obj.loadable() && obj.compilable();
        end

        function ld = loadable(obj)
            try
                load_system(obj.root_model_path);
                ld = 1;
            catch
                ld = 0;
            end
        end

        function cp = compilable(obj)
            Helper.make_garbage()
            project_dir = Helper.project_dir;
            try
                eval([char(obj.model_name), '([],[],[],''compile'');']);
                cp = 1;
                eval([char(obj.model_name), '([],[],[],''term'');']);
                close_system(obj.path)
            catch
                cp = 0;
            end
            cd(project_dir)
            Helper.clear_garbage();
        end
    end

    methods (Static)
        function eq_sub = find_eq_sub(sub, eq_classes)
            eq_sub = [];
            hash = sub.interface_hash();
            

        end
    end
end