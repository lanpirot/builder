classdef ModelMutator
    properties
        uuid
        version = 0;
        original_model_path
        original_model_name

        model_name
        root_model_path

        num_original_subsystems
        num_switched_subsystems

        built_correct = 0;
    end
    
    methods
        function obj = ModelMutator(uuid, root_model_identity)
            try
                obj.uuid = uuid;

                obj.original_model_name = root_model_identity.get_model_name();
                obj.original_model_path = root_model_identity.(Helper.model_path);
    
                obj = obj.copy_version(0);

                Helper.with_preserved_cfg(@close_system, obj.root_model_path, 0)
            catch ME
                Helper.log('log_construct', string(jsonencode(obj)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line)
                obj.version = -1;
            end
        end

        function obj = save_version(obj)
            obj.version = obj.version + 1;
            new_suffix = "v" + string(obj.version);
            %check whether the system with new system name is currently open
            new_name = extractBefore(obj.root_model_path, strlength(obj.root_model_path)-3) + new_suffix + extractAfter(obj.root_model_path, strlength(obj.root_model_path)-4);
            Helper.with_preserved_cfg(@save_system, obj.model_name, new_name)
            Helper.with_preserved_cfg(@close_system, obj.model_name + new_suffix, 0)
        end

        function obj = copy_version(obj, close_first)
            obj.model_name = "model" + string(obj.uuid);
            obj.root_model_path = Helper.mutate_playground + filesep + obj.model_name + extractAfter(obj.original_model_path,strlength(obj.original_model_path)-4);
            obj.root_model_path = char(obj.root_model_path.replace("\", "/"));
            if close_first
                Helper.with_preserved_cfg(@close_system, obj.root_model_path, 0)
            end
            delete(obj.root_model_path)
            pause(0.05);            %hacky to avoid: The requested operation cannot be performed on a file with a user-mapped section open.
            copyfile(obj.original_model_path, obj.root_model_path);

            Helper.with_preserved_cfg(@load_system, obj.root_model_path);
            set_param(obj.model_name, 'Lock', 'off')
            set_param(obj.model_name, "LockLinksToLibrary", "off")%sometimes causes errors
        end

        function obj = switch_subs_in_model(obj, name2subinfo)
            Helper.with_preserved_cfg(@load_system, obj.root_model_path);
            
            curr_depth = 0;
            while 1
                sub_at_depth_found = 0;
                sub_names = Helper.find_subsystems(obj.model_name);
                sub_names{end + 1} = char(obj.model_name);
                for i = 1:length(sub_names)
                    try
                        original_name = get_param(sub_names{i}, 'Name');
                    catch ME
                        Helper.log('log_copy_to_missing', string(jsonencode(obj)) + newline + sub_names{i} + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                        continue
                    end
                    original_parent = Helper.change_root_parent(get_param(sub_names{i}, 'Parent'), obj.original_model_name);
                    if isempty(original_parent)
                        original_name = obj.original_model_name;
                    end
                    key = struct(Helper.sub_name, original_name, Helper.sub_parents, original_parent, Helper.model_path, obj.original_model_path);

                    if ~name2subinfo.isKey({key})
                        continue
                    end
                    curr_sub = Subsystem(name2subinfo{{key}});
                    try
                        if curr_sub.local_depth == curr_depth
                            sub_at_depth_found = 1;
                            obj = obj.switch_sub(curr_sub, name2subinfo);
                        end
                    catch ME
                        Helper.log('log_switch_up', string(jsonencode(obj)) + newline + jsonencode(key) + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
                        continue
                    end
                    obj.copy_version(1);
                end
                if ~sub_at_depth_found && curr_depth
                    break;
                end
                curr_depth = curr_depth + 1;
            end
            Helper.with_preserved_cfg(@close_system, obj.root_model_path, 0)
            delete(obj.root_model_path)
        end

        function obj = switch_sub(obj, old_sub, name2subinfo)           
            [new_subs, mappings] = ModelMutator.find_equivalent_subs_and_mappings(old_sub, name2subinfo);
            %new_subs{2} = new_subs{1}
            %mappings{2} = mappings{1}

            if length(new_subs) > 1
                next_sub_index = ModelMutator.choose_new_sub(old_sub, new_subs);
                new_sub = Subsystem(new_subs{next_sub_index});
                mapping = mappings{next_sub_index};
                obj = obj.switch_sub_with_sub(old_sub, new_sub, mapping);
                obj = obj.check_models_correctness();
                if obj.built_correct
                    obj = obj.save_version();
                end
            end
        end
        
        function obj = switch_sub_with_sub(obj, old_sub, new_sub, mapping)
            copy_from = new_sub.identity;
            Helper.with_preserved_cfg(@load_system, copy_from.model_path);
            copy_to = Identity(old_sub.identity.sub_name, Helper.change_root_parent(old_sub.identity.sub_parents, char(obj.model_name)), obj.root_model_path);
            copied_element = Identity(['sub' int2str(Helper.found_alt(1))], copy_to.sub_parents, obj.root_model_path);
            copy_to = ModelMutator.copy_SS(obj.model_name, obj.root_model_path, copy_from, copy_to, copied_element, mapping);
            ModelMutator.annotate(copy_to.get_qualified_name(), "Copied system from: " + copy_from.get_qualified_name() + newline + " into: " + old_sub.identity.hash())
            %BuilderModel.annotate(copy_to.model_name, "Copied system into: " + '<a href="matlab:open_system(''' + copy_to.ancestor_names + ''')">Click Here</a>')
            ModelMutator.annotate(obj.model_name, "Copied " + copy_from.get_qualified_name() + " to: " + copy_to.get_qualified_name())
        end

        function obj = check_models_correctness(obj)
            obj.built_correct = obj.loadable() && (~Helper.needs_to_be_compilable || obj.compilable());
        end

        function ld = loadable(obj)
            try
                Helper.with_preserved_cfg(@load_system, obj.root_model_path);
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
            catch ME
                if contains(pwd, "tmp_garbage")
                    cd("..")
                end
                Helper.log('log_compile', string(jsonencode(obj)) + newline + ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line)
                cp = 0;
            end
            if contains(pwd, "tmp_garbage")
                cd("..")
            end
            Helper.clear_garbage();
        end
    end

    methods (Static)
        function [new_subs, mappings] = find_equivalent_subs_and_mappings(old_sub, name2subinfo)
            new_subs = {}; mappings = {};
            keys = name2subinfo.keys();
            for i=1:length(keys)
                alt_sub = name2subinfo{keys(i)};
                mapping = old_sub.interface.get_mapping(alt_sub.(Helper.interface));
                if isstruct(mapping)
                    if ~all(1:length(mapping.outmapping) == mapping.outmapping)
                        disp(mapping)
                    end
                    new_subs{end + 1} = alt_sub;
                    mappings{end + 1} = mapping;
                end
            end
        end

        function index = choose_new_sub(old_sub, new_subs)
            %remove current sub from alt_subs, as to get a real alternative sub
            new_subs(ModelMutator.find_identical(old_sub, new_subs)) = [];

            %sort alt_subs by depth
            [max_index, min_index] = ModelMutator.get_extremes(new_subs, Helper.local_depth);
            if Helper.wish_property == Helper.deep
                index = max_index;
                return
            elseif Helper.wish_property == Helper.shallow
                index = min_index;
                return
            end
            
            %neither: choose a random sub
            index = randi(length(new_subs));
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
                if sub.is_identical(subs{i})
                    index = i;
                    return
                end
            end
        end        

        function connections = get_wiring(subsystem)
            connections = struct;
            try
            lines = get_param(subsystem, 'LineHandles');
            catch ME
                disp("")
            end

            connections.in_source_ports = ModelMutator.get_wiring_of(lines.Inport, "SrcPortHandle");
            connections.out_destination_ports = ModelMutator.get_wiring_of(lines.Outport, "DstPortHandle");
            connections.Enable = ModelMutator.get_wiring_of(lines.Enable, "SrcPortHandle");
            connections.Trigger = ModelMutator.get_wiring_of(lines.Trigger, "SrcPortHandle");

            connections.LConn = {};
            connections.RConn = {};
            pc = get_param(subsystem, 'PortConnectivity');
            for i=1:length(pc)
                if startsWith(pc(i).Type, 'LConn')
                    connections.LConn{end + 1} = pc(i).DstPort;
                elseif startsWith(pc(i).Type, 'RConn')
                    connections.LConn{end + 1} = pc(i).DstPort;
                end
            end
            connections.Ifaction = get_param(lines.Ifaction, "SrcPortHandle");
            connections.Reset = lines.Reset;
        end

        function out_connection = get_wiring_of(lines_in, param_string)
            out_connection = {};
            for i=1:length(lines_in)
                line = lines_in(i);
                if line == -1
                    out_connection{end + 1} = -1;
                else
                    out_connection{end + 1} = get_param(line, param_string);
                end
            end
        end

        function remove_lines(subsystem)
            try
            line_handles = get_param(subsystem, "LineHandles");
            catch ME
                disp("")
            end

            
            ModelMutator.remove_lines2(line_handles.Inport);
            ModelMutator.remove_lines2(line_handles.Outport);
            ModelMutator.remove_lines2(line_handles.Enable);
            ModelMutator.remove_lines2(line_handles.Trigger);
            ModelMutator.remove_lines2(line_handles.LConn);
            ModelMutator.remove_lines2(line_handles.RConn);
            ModelMutator.remove_lines2(line_handles.Ifaction);
            ModelMutator.remove_lines2(line_handles.Reset);
            ModelMutator.remove_lines2(line_handles.Event);
        end

        function make_subsystem_editable(subsystem)
            while Helper.get_depth(subsystem) > 0 && get_param(subsystem, "LinkStatus") ~= "none"
                try
                    set_param(subsystem, "LinkStatus", "none")
                catch
                end
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

        function copy_to = copy_SS(model_name, model_path, copy_from, copy_to, copied_element, mapping)
            if copy_to.is_root()
                copy_to = ModelMutator.copy_to_root(model_name, model_path, copy_from, copy_to);
            else
                copy_to = ModelMutator.copy_to_non_root(copy_to, copy_from, copied_element, mapping);
            end
        end

        function [copy_to, additional_level] = copy_to_root(model_name, root_model_path, copy_from, copy_to)
            additional_level = 0;
            if copy_from.is_root()
                %copy from root to root
                root_model_path = root_model_path + copy_from.model_path(end-3:end);
                copyfile(copy_from.model_path, root_model_path);
                Helper.with_preserved_cfg(@load_system, root_model_path);
                copy_to = Identity(char(model_name), '', root_model_path);
            else
                %copy from subsystem to root
                delete(root_model_path);Helper.with_preserved_cfg(@close_system, model_name, 0);%in mutate.m, the file exists, here
                new_system(model_name);
                Helper.with_preserved_cfg(@save_system, model_name, root_model_path);
                Helper.with_preserved_cfg(@load_system, copy_from.model_path);


                copy_to.sub_name = model_name;
                Simulink.BlockDiagram.deleteContents(copy_to.get_qualified_name())
                % try
                %     Simulink.SubSystem.copyContentsToBlockDiagram(copy_from.get_qualified_name(), copy_to.get_qualified_name())
                % catch
                    %if it is a stateflow chart or non-root allowed subsystem
                    additional_level = 1;
                    add_block(copy_from.get_qualified_name(), copy_to.get_qualified_name()+"/"+copy_from.sub_name,'CopyOption','nolink');
                    copy_to.sub_parents = copy_to.sub_name;
                    copy_to.sub_name = copy_from.sub_name;                    
                %end
            end
            %set_param(copy_to.get_qualified_name(),"Lock","off")
            %ModelMutator.resolve_all_links(copy_to.get_qualified_name())
            %we don't need to rewire the inputs/outputs after copying
        end

        function resolve_all_links(sys_name)
            handle = get_param(sys_name,'handle');
            subsystem_handles = Helper.find_subsystems(handle);
            for i = 1:length(subsystem_handles)
                try
                    set_param(subsystem_handles(i),'LinkStatus','none')
                catch
                end
            end
        end

        function copy_to = copy_to_non_root(copy_to, copy_from, copied_element, mapping)
            %get prior wiring
            try
                get_param(copy_to.get_qualified_name(),'handle');
            catch
                copy_to.sub_name = [copy_to.sub_name  ' synthed'];
            end
            connected_blocks = ModelMutator.get_wiring(copy_to.get_qualified_name());
            ModelMutator.make_subsystem_editable(copy_to.get_qualified_name())
            ModelMutator.remove_lines(copy_to.get_qualified_name());
            if strcmp(copy_to.sub_name, 'OperationalStateMachine')
                disp(copy_to.sub_parents)
                disp("")
            end

            delete_block(copy_to.get_qualified_name())
            if copy_from.is_root()
                %copy from root to subsystem
                add_block('built-in/Subsystem', copied_element.get_qualified_name())
                Simulink.BlockDiagram.copyContentsToSubsystem(copy_from.get_qualified_name(), copied_element.get_qualified_name())
                set_param(copied_element.get_qualified_name(), 'Name', copy_to.get_sub_name_for_diagram())
            else
                %copy from subsystem to subsystem
                add_block(copy_from.get_qualified_name(), copy_to.get_qualified_name(),'CopyOption','nolink');
            end
            %now, rewire
            ModelMutator.add_lines(copy_to, connected_blocks, mapping)
            %ModelMutator.resolve_all_links(copy_to.get_qualified_name())
        end

        function add_lines(system, ports, mapping)
            ph = get_param(system.get_qualified_name(), "PortHandles");
            for i=1:length(ports.in_source_ports)
                if ports.in_source_ports{i} ~= -1
                    add_line(system.sub_parents, ports.in_source_ports{i}, ph.Inport(mapping.inmapping(i)), 'autorouting','on')
                end
            end
            for i=1:length(ports.out_destination_ports)
                outports = ports.out_destination_ports{i};
                if outports ~= -1
                    for j=1:length(outports)
                        add_line(system.sub_parents, ph.Outport(mapping.outmapping(i)), outports(j), 'autorouting','on')
                    end
                end
            end
            ModelMutator.add_special_lines(system, ports, ph)
        end

        function add_special_lines(system, ports, ph)
            special_lines = {{ports.Enable,ph.Enable}, {ports.Trigger,ph.Trigger}, {[ports.LConn ports.RConn],[ph.LConn ph.RConn]},{ph.Ifaction,ports.Ifaction},{ports.Reset, ph.Reset}};
            for i=1:length(special_lines)
                srcdsts = special_lines{i};
                
                dsts = srcdsts{1};
                for d=1:length(dsts)
                    if isfloat(dsts)
                        dests = dsts;
                    else
                        dests = dsts{d};
                        if iscell(dsts{d})
                            dests = dsts{1};
                        end
                    end
                    src = srcdsts{2};
                    src = src(d);
                    for j=1:length(dests)
                        try
                            if strcmp(get_param(src, 'PortType'), 'outport')
                                add_line(system.sub_parents, src, dests(j), 'autorouting','on');
                            else
                                add_line(system.sub_parents, dests(j), src, 'autorouting','on');
                            end
                        catch
                        end
                    end
                end
            end
        end

        function annotate(system, text)
            a = Simulink.Annotation(system, string(randi(1000)));
            a.FontSize = 18;
            a.BackgroundColor = 'lightBlue';
            %a.Interpreter = 'rich';
            a.Text = text;
        end
    end
end