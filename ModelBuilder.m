classdef ModelBuilder
    properties
        uuid
        version = 0;
        original_model_path
        original_model_name

        model_name
        root_model_path

        num_original_subsystems
        num_switched_subsystems

        built_correct

        skip_save = 0;
    end
    
    methods
        function obj = ModelBuilder(uuid, root_model_identity)
            try
                obj.uuid = uuid;
                obj.original_model_name = Helper.get_model_name(root_model_identity.model_path);
                obj.original_model_path = root_model_identity.(Helper.model_path);
    
                obj = obj.copy_version(0);
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

        function obj = switch_subs_in_model(obj, name2subinfo)
            load_system(obj.root_model_path);
            
            curr_depth = 1;
            while 1
                sub_at_depth_found = 0;
                sub_names = Helper.find_subsystems(obj.model_name);
                sub_names{end + 1} = char(obj.model_name);
                for i = 1:length(sub_names)
                    original_name = get_param(sub_names{i}, 'Name');
                    original_parent = Helper.change_root_parent(get_param(sub_names{i}, 'Parent'), obj.original_model_name);
                    if isempty(original_parent)
                        original_name = obj.original_model_name;
                    end
                    key = struct(Helper.sub_name, original_name, Helper.sub_parents, original_parent, Helper.model_path, obj.original_model_path);
                    try
                        keyhit = name2subinfo({key});
                        curr_sub = Subsystem(keyhit{1});
                    catch ME
                        Helper.log('log_switch_up', string(jsonencode(obj)) + newline + jsonencode(key) + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                        continue
                    end
                    if curr_sub.sub_depth == curr_depth && ~curr_sub.skip_it
                        sub_at_depth_found = 1;
                        obj = obj.switch_sub(curr_sub, name2subinfo);
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

        function obj = switch_sub(obj, old_sub, name2subinfo)           
            new_subs = ModelBuilder.find_equivalent_subs(old_sub, name2subinfo);

            if length(new_subs) > 1
                new_sub = Subsystem(ModelBuilder.choose_new_sub(old_sub, new_subs));
                obj = obj.switch_sub_with_sub(old_sub, new_sub);
                obj = obj.check_models_correctness();
                if obj.skip_save == 0
                    obj = obj.save_version();
                end
                obj = obj.copy_version(1);
            end
        end
        
        function obj = switch_sub_with_sub(obj, old_sub, new_sub)
            %    disp(obj)
            %    disp(old_sub)
            %    disp(new_sub)
            %    disp(mapping)


            %load_system(new_sub.model_path);
            %new_sub.handle = get_param(new_sub.qualified_name, 'Handle');
            
            %copy_from = new_sub
            %copy_to = Helper.change_root_parent(old_sub.qualified_name, char(obj.model_name));%within model_name/root_model_path the relative path of old_sub
            %copied_element_name = ['sub' int2str(Helper.found_alt(1))];
            %copied_qualified_name = [copy_to '/' copied_element_name];
            

            alt_model_path = new_sub.model_path;
            alt_sub_qualified_name = new_sub.qualified_name;
            switch_model_handle = load_system(alt_model_path);
            load_system(alt_sub_qualified_name)
            switch_sub_handle = get_param(alt_sub_qualified_name, 'Handle');


            copy_from = SimulinkName(SimulinkName.get_qualified_name_from_handle(get_param(switch_model_handle, 'Name'), switch_sub_handle), get_param(switch_model_handle, 'Name'));
            copy_to = SimulinkName(SimulinkName.get_qualified_name_from_handle(get_param(obj.model_name, 'Name'), Helper.change_root_parent(old_sub.qualified_name, char(obj.model_name))), obj.original_model_name);

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
                    Simulink.BlockDiagram.createSubsystem(get_param(copy_to.full_name, 'Handle'), 'Name', copied_name.element_name) %creating wrapping subystem to not disturb subystem's innards (e.g. stateflow)
                    Simulink.SubSystem.deleteContents(copied_name.full_name)
                    Simulink.BlockDiagram.copyContentsToSubsystem(copy_from.full_name, copied_name.full_name)
                    set_param(copied_name.full_name, 'Name', copy_to.element_name)
                else
                    %copy from subsystem to subsystem
                    delete_block(copy_to.full_name)
                    add_block(copy_from.full_name, copy_to.full_name)
                end
                %now, rewire
                ModelBuilder.add_lines(copy_to, connected_blocks, old_sub.interface.mapping, new_sub.interface.mapping)
            end
            ModelBuilder.annotate(copy_to.full_name, "Copied system from: " + alt_sub_qualified_name + newline + " into: " + SimulinkName.name_hash(obj.original_model_path, copy_to.original_full_name))
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
            if contains(pwd, "tmp_garbage")
                cd("..")
            end
            Helper.clear_garbage();
        end
    end

    methods (Static)
        function new_subs = find_equivalent_subs(old_sub, name2subinfo)
            new_subs = {};
            keys = name2subinfo.keys();
            for i=1:length(keys)
                alt_sub = name2subinfo{keys(i)};
                if old_sub.interface.is_equivalent(alt_sub.(Helper.interface))
                    new_subs{end + 1} = alt_sub;
                end
            end
        end

        function other_sub = choose_new_sub(old_sub, new_subs)
            %remove current sub from alt_subs, as to get a real alternative sub
            new_subs(ModelBuilder.find_identical(old_sub, new_subs)) = [];
            if isempty(new_subs)
                disp("")
            end

            %sort alt_subs by diverseness
            [max_index, min_index] = ModelBuilder.get_extremes(new_subs, Helper.diverseness);
            if Helper.wish_property == Helper.diverse
                other_sub = new_subs{max_index};
                return
            elseif Helper.wish_property == Helper.mono
                other_sub = new_subs{min_index};
                return
            end

            %sort alt_subs by depth
            [max_index, min_index] = ModelBuilder.get_extremes(new_subs, Helper.sub_depth);
            if Helper.wish_property == Helper.deep
                other_sub = new_subs{max_index};
                return
            elseif Helper.wish_property == Helper.shallow
                other_sub = new_subs{min_index};
                return
            end
            
            %neither: choose a random sub
            other_sub = new_subs{randi(length(new_subs))};
        end

        function [min_index, max_index] = get_extremes(subs, keyword)
            min_index = -1; max_index = -1;
            minimum = 2^32; maximum = -2^31;
            
            for i=1:length(subs)
                curr_val = subs{i}.(keyword);
                if curr_val < minimum
                    minimum = curr_val;
                    min_index = i;
                end
                if curr_val > maximum
                    maximum = curr_val;
                    max_index = i;
                end
            end
            if min_index < 0 || max_index < 0
                dips("")
            end
        end

        function index = find_identical(sub, subs)
            index = -1;
            for i=1:length(subs)
                if sub.num_contained_elements == subs{i}.(Helper.num_contained_elements)
                    index = i;
                    return
                end
            end
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
                    connections.out_destination_ports{end + 1} = -1;
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

        function add_lines(system, ports, old_mapping, new_mapping)
            ph = get_param(system.full_name, "PortHandles");
            for i=1:length(ports.in_source_ports)
                if ports.in_source_ports{old_mapping.in_mapping(i)} ~= -1
                    add_line(system.ancestor_names, ports.in_source_ports{old_mapping.in_mapping(i)}, ph.Inport(new_mapping.in_mapping(i)), 'autorouting','on')
                end
            end
            for i=1:length(ports.out_destination_ports)
                outports = ports.out_destination_ports{old_mapping.out_mapping(i)};
                if outports ~= -1
                    for j=1:length(outports)
                        add_line(system.ancestor_names, ph.Outport(new_mapping.out_mapping(i)), outports(j), 'autorouting','on')
                    end
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