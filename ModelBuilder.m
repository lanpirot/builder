classdef ModelBuilder
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

        skip_save = 0;
    end
    
    methods
        function obj = ModelBuilder(uuid, root_model)
            try
                obj.uuid = uuid;
                tmp = split(root_model.(Helper.name), Helper.second_level_divider);
                obj.original_model_name = string(tmp{end});
                obj.original_model_path = tmp{1};
    
                obj = obj.copy_version(0);
    
    
                
                obj.num_original_subsystems = length(Helper.get_contained_subsystems(get_param(obj.model_name, 'Handle')));
                close_system(obj.root_model_path, 0)
            catch ME
                Helper.log('log_construct', string(jsonencode(obj)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line)
                obj.version = -1;
            end
        end

        function obj = save_version(obj)
            obj.version = obj.version + 1;
            new_suffix = "v" + string(obj.version);
            %check whether the system with new system name is currently open
            save_system(obj.model_name, extractBefore(obj.root_model_path, strlength(obj.root_model_path)-3) + new_suffix + extractAfter(obj.root_model_path, strlength(obj.root_model_path)-4))
            close_system(obj.model_name + new_suffix)
        end

        function obj = copy_version(obj, close_first)            
            obj.model_name = "model" + string(obj.uuid);
            obj.root_model_path = Helper.playground + filesep + obj.model_name + extractAfter(obj.original_model_path,strlength(obj.original_model_path)-4);
            obj.root_model_path = char(obj.root_model_path.replace("\", "/"));
            if close_first
                close_system(obj.root_model_path, 0)
            end
            delete(obj.root_model_path)
            pause(0.05);            %hacky to avoid: The requested operation cannot be performed on a file with a user-mapped section open.
            copyfile(obj.original_model_path, obj.root_model_path);
            load_system(obj.root_model_path)
            set_param(obj.model_name, "LockLinksToLibrary", "off")%sometimes causes errors
        end

        function obj = switch_subs_in_model(obj, name2subinfo, interface2name)
            load_system(obj.root_model_path);
            
            curr_depth = 0;
            while 1
                sub_at_depth_found = 0;
                sub_names = Helper.find_subsystems(obj.model_name);
                sub_names{end + 1} = char(obj.model_name);
                for i = 1:length(sub_names)
                    sub_name = sub_names{i};
                    if curr_depth == 0 && SimulinkName.is_root(sub_name) || Helper.get_depth(sub_name) == curr_depth && Subsystem.is_subsystem(sub_name) && ~SimulinkName.is_root(sub_name)
                        sub_at_depth_found = 1;
                        obj = obj.switch_sub(obj.model_name, sub_name, name2subinfo, interface2name);
                    end
                end
                if ~sub_at_depth_found
                    break;
                end
                curr_depth = curr_depth + 1;
            end
            close_system(obj.root_model_path, 0);
            delete(obj.root_model_path)
        end

        function obj = switch_sub(obj, model_name, sub_name, name2subinfo, interface2name)
            qualified_name = SimulinkName.get_qualified_name_from_handle(obj.original_model_name, sub_name);
            sub_complete_name = SimulinkName.name_hash(obj.original_model_path, qualified_name);
            sub_interface = Helper.get_info(name2subinfo, sub_complete_name, Helper.ntrf);
            alt_complete_names = interface2name({sub_interface});
            alt_complete_names = alt_complete_names{1};

            if length(alt_complete_names) > 1
                other_sub_complete_name = ModelBuilder.choose_other_sub(sub_complete_name, alt_complete_names, name2subinfo);
                sub_mapping = Helper.get_info(name2subinfo, sub_complete_name, Helper.mapping);
                alt_mapping = Helper.get_info(name2subinfo, other_sub_complete_name, Helper.mapping);
                obj = obj.switch_sub_with_sub(model_name, sub_name, other_sub_complete_name, sub_mapping, alt_mapping);
                obj = obj.check_models_correctness();
                if obj.skip_save == 0
                    obj = obj.save_version();
                end
                obj = obj.copy_version(1);
            end
        end

        function obj = switch_sub_with_sub(obj, model_name, sub_name, alternate_sub_name, sub_mapping, alt_mapping)
            %if ~all(sub_mapping.in_mapping == alt_mapping.in_mapping) || ~all(sub_mapping.out_mapping == alt_mapping.out_mapping)
            %    disp(obj)
            %    disp(model_name)
            %    disp(sub_name)
            %    disp(alternate_sub_name)
            %    disp(sub_mapping.in_mapping)
            %    disp(sub_mapping.out_mapping)
            %    disp(alt_mapping.in_mapping)
            %    disp(alt_mapping.out_mapping)
            %end


            [alt_model_path, alt_sub_qualified_name] = SimulinkName.unfuse_hash(alternate_sub_name);
            switch_model_handle = load_system(alt_model_path);
            load_system(alt_sub_qualified_name)
            switch_sub_handle = get_param(alt_sub_qualified_name, 'Handle');


            copy_from = SimulinkName(SimulinkName.get_qualified_name_from_handle(get_param(switch_model_handle, 'Name'), switch_sub_handle), get_param(switch_model_handle, 'Name'));
            copy_to = SimulinkName(SimulinkName.get_qualified_name_from_handle(get_param(model_name, 'Name'), sub_name), obj.original_model_name);

            copied_name = SimulinkName(join([copy_to.ancestor_names "sub" + string(Helper.found_alt(1))], "/"), obj.original_model_name);
            if copy_to.root_bool
                
                if copy_from.root_bool
                    %copy from root to root
                    close_system(obj.model_name)
                    delete(obj.root_model_path)
                    copyfile(alt_model_path, obj.root_model_path);
                    load_system(obj.root_model_path);
                else
                    %copy from subsystem to root
                    Simulink.BlockDiagram.deleteContents(copy_to.full_name)
                    try
                        Simulink.SubSystem.copyContentsToBlockDiagram(copy_from.full_name, copy_to.full_name)
                    catch ME
                        obj.skip_save = 1;
                        Helper.log('log_switch_up', string(jsonencode(obj)) + newline + alternate_sub_name + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                        return
                    end
                end
                %we don't need to rewire the inputs/outputs after copying
            else
                %get prior wiring
                connected_blocks = ModelBuilder.get_wiring(copy_to.full_name);
                ModelBuilder.remove_lines(copy_to.full_name);
                if copy_from.root_bool
                    %copy from root to subsystem
                    Simulink.BlockDiagram.createSubsystem(get_param(sub_name, 'Handle'), 'Name', copied_name.element_name) %creating wrapping subystem to not disturb subystem's innards (e.g. stateflow)
                    Simulink.SubSystem.deleteContents(copied_name.full_name)
                    Simulink.BlockDiagram.copyContentsToSubsystem(copy_from.full_name, copied_name.full_name)
                    set_param(copied_name.full_name, 'Name', copy_to.element_name)
                else
                    %copy from subsystem to subsystem
                    delete_block(copy_to.full_name)
                    add_block(copy_from.full_name, copy_to.full_name)
                end
                %now, rewire
                ModelBuilder.add_lines(copy_to, connected_blocks, sub_mapping, alt_mapping)
            end
            ModelBuilder.annotate(copy_to.full_name, "Copied system from: " + alternate_sub_name + newline + " into: " + SimulinkName.name_hash(obj.original_model_path, copy_to.original_full_name))
            %BuilderModel.annotate(copy_to.model_name, "Copied system into: " + '<a href="matlab:open_system(''' + copy_to.ancestor_names + ''')">Click Here</a>')
            ModelBuilder.annotate(copy_to.model_name, "Copied " + copy_from.full_name + " to: " + copy_to.full_name)
        end

        function obj = check_models_correctness(obj)
            obj.built_correct = obj.loadable() && (~Helper.needs_to_be_compilable || obj.compilable());
            if ~obj.built_correct
                obj.skip_save = 1;
            end
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
            Helper.create_garbage_dir()
            project_dir = Helper.project_dir;
            try
                eval([char(obj.model_name), '([],[],[],''compile'');']);
                cp = 1;
                try
                    while 1
                        eval([char(obj.model_name), '([],[],[],''term'');']);
                    end
                catch
                end
            catch
                cp = 0;
            end
            cd(project_dir)
            Helper.clear_garbage();
        end
    end

    methods (Static)
        function other_sub = choose_other_sub(sub, alt_subs, name2subinfo)
            %remove current sub from alt_subs, as to get a real alternative sub
            alt_subs(strcmp(alt_subs,sub)) = [];
            if isempty(alt_subs)
                disp("")
            end

            %sort alt_subs by diverseness
            alt_subs = ModelBuilder.sort_subs(alt_subs, Helper.diverseness, name2subinfo);
            if Helper.wish_property == Helper.diverse
                other_sub = alt_subs{end};
                return
            elseif Helper.wish_property == Helper.mono
                other_sub = alt_subs{1};
                return
            end

            %sort alt_subs by depth
            alt_subs = ModelBuilder.sort_subs(alt_subs, Helper.depth, name2subinfo);
            if Helper.wish_property == Helper.deep
                other_sub = alt_subs{end};
                return
            elseif Helper.wish_property == Helper.shallow
                other_sub = alt_subs{1};
                return
            end
            
            %neither: choose a random sub
            other_sub = alt_subs{randi(length(alt_subs))};
        end

        function subs = sort_subs(subs, keyword, name2subinfo)
            names_keyword = struct(Helper.name, {}, keyword, {});
            for i=1:length(subs)
                names_keyword(end + 1) = struct(Helper.name, subs{i}, keyword, Helper.get_info(name2subinfo, subs{i}, keyword));
            end
            

            [sorted_subs, ~] = Helper.sort_by_field(names_keyword, keyword);
            subs = extractfield(sorted_subs, Helper.name);
        end

        function connections = get_wiring(subsystem)
            connections = struct;
            connections.in_source_ports = {};
            connections.out_destination_ports = {};
            lines = get_param(subsystem, 'LineHandles');            
            for i=1:length(lines.Inport)
                line = lines.Inport(i);
                if line == -1
                    connections.in_source_ports{end + 1} = -1;
                else
                    connections.in_source_ports{end + 1} = get_param(line, "SrcPortHandle");
                end
            end

            for i=1:length(lines.Outport)
                line = lines.Outport(i);
                if line == -1
                    connections.in_source_ports{end + 1} = -1;
                else
                    connections.out_destination_ports{end + 1} = get_param(line, "DstPortHandle");
                end
            end
        end

        function remove_lines(subsystem)
            line_handles = get_param(subsystem, "LineHandles");

            ModelBuilder.make_subsystem_editable(subsystem)
            ModelBuilder.remove_lines2(line_handles.Inport);
            ModelBuilder.remove_lines2(line_handles.Outport);
        end

        function make_subsystem_editable(subsystem)
            while Helper.get_depth(subsystem) > 0 && get_param(subsystem, "LinkStatus") ~= "none"
                set_param(subsystem, "LinkStatus", "none")
                subsystem = get_param(subsystem, "Parent");
            end
        end

        function remove_lines2(lines)
            for i = 1:length(lines)
                if lines(i) ~= -1
                    delete_line(lines(i))
                end
            end
        end

        function add_lines(system, ports, sub_mapping, alt_mapping)
            ph = get_param(system.full_name, "PortHandles");
            for i=1:length(ports.in_source_ports)
                if ports.in_source_ports{i} ~= -1
                    add_line(system.ancestor_names, ports.in_source_ports{sub_mapping.in_mapping(i)}, ph.Inport(alt_mapping.in_mapping(i)), 'autorouting','on')
                end
            end
            for i=1:length(ports.out_destination_ports)
                outports = ports.out_destination_ports{sub_mapping.out_mapping(i)};
                for j=1:length(outports)
                    add_line(system.ancestor_names, ph.Outport(alt_mapping.out_mapping(i)), outports(j), 'autorouting','on')
                end
            end
        end

        function annotate(system, text)
            a = Simulink.Annotation(system, '');
            a.FontSize = 18;
            a.BackgroundColor = 'lightBlue';
            a.Interpreter = 'rich';
            a.Text = text;
        end
    end
end