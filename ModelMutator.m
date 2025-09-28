classdef ModelMutator    
    methods(Static)

        function add_ports(from, to)
            connections = get_param(from, "PortHandles");
            for i = 1:numel(connections.Inport)
                add_block('built-in/Inport', to+"/TmpTMPIn"+i)
            end
            for i = 1:numel(connections.Outport)
                add_block('built-in/Outport', to+"/TmpTMPOut"+i)
            end
            if ~isempty(connections.Enable)
                add_block(Helper.find_ports(from, 'EnablePort'), to+"/EnablePort")
            end
            if ~isempty(connections.Trigger)
                add_block(Helper.find_ports(from, 'TriggerPort'), to+"/TriggerPort")
            end
            if ~isempty(connections.Ifaction)
                add_block(Helper.find_ports(from, 'ActionPort'), to+"/ActionPort")
            end
            if ~isempty(connections.Reset)
                add_block(Helper.find_ports(from, 'ResetPort'), to+"/ResetPort")
            end
        end

        function [new_block_name, number] = get_number(new_block_name, inout, number, dict, dst_port_handle)
            if exist('dst_port_handle', 'var') && contains('triggerenableifactionReset', get_param(dst_port_handle, 'PortType'))
                switch get_param(dst_port_handle, 'PortType')
                    case 'trigger'
                        number = 'trigger';
                    case 'enable'
                        number = 'enable';
                    case 'ifaction'
                        number = 'ifaction';
                    case 'Reset'
                        number = 'Reset';
                    otherwise
                        keyboard
                end
            end

            if dict.isKey(new_block_name)
                val = dict(new_block_name);
                mapping = val.mapping;
                if isnumeric(number)
                    if strcmp(inout, 'src')
                        number = mapping.outmapping(number);
                    else
                        try
                        number = mapping.inmapping(number);
                        catch ME
                            keyboard
                        end
                    end
                end
                new_block_name = get_param(val.block_fullname_new, 'Name');
            end
        end


        function [holes, dict] = init(copy_to, original_children, new_children)
            holes = {};
            if copy_to.is_root()
                new_system(copy_to.sub_name);
            end

            global name2subinfo_complete
            dict = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for o = 1:numel(original_children)
                old_interface = Interface(name2subinfo_complete{{original_children(o)}}.(Helper.interface));
                new_interface = Interface(name2subinfo_complete{{struct(new_children{o}.identity)}}.(Helper.interface));
                value.mapping = old_interface.get_mapping(new_interface);

                key = replace(original_children(o).sub_name, '//', '#');
                value.block_fullname_new = [copy_to.get_qualified_name() '/' replace(new_children{o}.identity.sub_name, '//', '#') '_' num2str(o) '_snth'];
                
                dict(key) = value;
                dict(value.block_fullname_new) = value;
            end
        end


        function holes = insert_blocks(copy_to, inner_blocks, dict, holes)
            global seen_gotos
            for i = 2:numel(inner_blocks)
                block_fullname = inner_blocks{i};
                split_name = replace(get_param(block_fullname, 'Name'), '/', '#');

                if dict.isKey(split_name)
                    block_fullname_new = dict(split_name).block_fullname_new;
                    h = add_block('built-in/Subsystem', block_fullname_new);
                    holes{end + 1} = get_param(h, 'Name');
                    set_param(block_fullname_new, 'Position', get_param(block_fullname, 'Position'));
                    ModelMutator.add_ports(block_fullname, block_fullname_new);
                else
                    block_fullname_new = [copy_to.get_qualified_name() '/' split_name];
                    if copy_to.is_root() || ~contains('InportOutportTriggerPortEnablePortActionPortResetPort', get_param(block_fullname, 'BlockType'))
                        try
                            add_block(block_fullname, block_fullname_new, 'CopyOption', 'nolink');
                        catch ME
                            switch get_param(block_fullname, "Blocktype")
                                case 'TransportDelay'
                                    add_block(['simulink/Quick Insert/Discrete/Discrete' newline 'Transfer Fcn'], block_fullname_new, 'CopyOption', 'nolink');
                                case 'TransferFcn'
                                    add_block(['simulink/Quick Insert/Discrete/Discrete' newline 'Transfer Fcn'], block_fullname_new, 'CopyOption', 'nolink');
                                case 'Integrator'
                                    add_block(['simulink/Discrete/Discrete-Time' newline 'Integrator'], block_fullname_new, 'CopyOption', 'nolink');
                                otherwise
                                    %last minute cleanup commando, not needed anymore, if commented blocks are also included in cleaning,m
                                    if strcmp(ME.identifier, 'Simulink:Engine:CallbackEvalErr') || strcmp(ME.identifier, 'MATLAB:MException:MultipleErrors')
                                        lock_links_masks = {'LinkStatus', 'none'; 'Lock', 'off'; 'LockLinksToLibrary', 'off'; 'Permissions', 'ReadWrite'; 'LinkStatus', 'none'; 'Lock', 'off'; 'LockLinksToLibrary', 'off'; 'Mask', 'off'};
                                        block_functions = {'OpenFcn' 'LoadFcn' 'MoveFcn' 'NameChangeFcn' 'PreCopyFcn' 'CopyFcn' 'ClipboardFcn' 'PreDeleteFcn' 'DeleteFcn' 'DestroyFcn' 'UndoDeleteFcn' 'InitFcn' 'StartFcn' 'ContinueFcn' 'PauseFcn' 'StopFcn' 'PreSaveFcn' 'PostSaveFcn' 'CloseFcn' 'ModelCloseFcn', 'DeleteChildFcn', 'ErrorFcn', 'ParentCloseFcn'};
                                        blocks = find_system(block_fullname, 'LookUnderMasks', 'on', 'FollowLinks','on', 'Variants','AllVariants', 'IncludeCommented', 'on');
                                        pathComponents = strsplit(block_fullname, '/');
                                        prefixPaths = cell(1, length(pathComponents));
                                        for i = 1:length(pathComponents)
                                            prefixPaths{i} = strjoin(pathComponents(1:i), '/');
                                        end
                                        blocks = [prefixPaths';blocks];

                                        for j = 1:numel(blocks)
                                            for ll = 1:size(lock_links_masks, 1)
                                                try
                                                    set_param(blocks{j}, lock_links_masks{ll, 1}, lock_links_masks{ll, 2});
                                                catch
                                                end
                                            end
                            
                                            for bf = 1:length(block_functions)
                                                try
                                                    set_param(blocks{j}, block_functions{bf}, '');
                                                catch
                                                end
                                            end
                                        end
                                        add_block(block_fullname, block_fullname_new, 'CopyOption', 'nolink')
                                        save_system(bdroot(block_fullname))
                                        continue
                                    end
                                    keyboard
                            end
                        end
                        if strcmp(get_param(block_fullname_new, "Blocktype"), 'Goto')
                            tag = get_param(block_fullname_new, "GotoTag");
                            if ismember(tag, seen_gotos)
                                tag = [tag num2str(length(seen_gotos))];
                                set_param(block_fullname_new, "GotoTag", tag);
                            end
                            seen_gotos{end+1} = tag;
                        end
                    else
                        block_type = get_param(block_fullname, 'BlockType');
                        present_ports = Helper.find_ports(copy_to.get_qualified_name, block_type);
                        if isscalar(present_ports)
                            set_param(present_ports, 'Name', split_name);
                        else
                            port_num = str2double(get_param(block_fullname, 'Port'));
                            try
                                set_param(present_ports(port_num), 'Name', split_name);
                            catch
                                add_block(['built-in/' block_type], [copy_to.get_qualified_name '/' split_name]);
                            end
                        end
                    end
                    set_param(Helper.full_path(copy_to.get_qualified_name, split_name), 'Position', get_param(block_fullname, 'Position'))
                end
            end
        end


        function insert_lines(copy_to, dict, inner_lines)
            for i = 1:numel(inner_lines)
                inner_line = inner_lines(i);
                src_port_handle = get_param(inner_line, 'SrcPortHandle');
                if src_port_handle < 0
                    continue
                end
                src_block = get_param(get_param(src_port_handle, 'Parent'), 'Name');
                src_block_new = replace(src_block, '/', '#');
                [src_block_new, src_block_number] = ModelMutator.get_number(src_block_new, 'src', get_param(src_port_handle, 'PortNumber'), dict);

                dst_port_handle = get_param(inner_line, 'DstPortHandle');
                if length(dst_port_handle) > 1 || dst_port_handle < 0
                    continue
                end

                dst_block = get_param(get_param(dst_port_handle, 'Parent'), 'Name');
                dst_block_new = replace(dst_block, '/', '#');
                [dst_block_new, dst_block_number] = ModelMutator.get_number(dst_block_new, 'dst', get_param(dst_port_handle, 'PortNumber'), dict, dst_port_handle);
                


                switch get_param(src_port_handle, 'PortType')
                    case 'outport'
                        try
                            add_line(copy_to.get_qualified_name, Helper.full_path(src_block_new, num2str(src_block_number)), Helper.full_path(dst_block_new, num2str(dst_block_number)), 'autorouting', 'on');
                        catch ME
                            if contains('TriggerPortEnablePort', get_param(Helper.full_path(copy_to.get_qualified_name, src_block_new), 'BlockType'))
                                set_param(Helper.full_path(copy_to.get_qualified_name, src_block_new), 'ShowoutputPort', 'on');
                                add_line(copy_to.get_qualified_name, Helper.full_path(src_block_new, num2str(src_block_number)), Helper.full_path(dst_block_new, num2str(dst_block_number)), 'autorouting', 'on');
                            else
                                keyboard
                            end
                        end
                    case 'state'
                        add_line(copy_to.get_qualified_name, Helper.full_path(src_block_new, 'state'), Helper.full_path(dst_block_new, num2str(dst_block_number)), 'autorouting', 'on');
                    case 'connection'
                        p1 = get_param(Helper.full_path(copy_to.get_qualified_name, src_block_new), "PortHandles");
                        if ismember(get_param(src_port_handle, 'Handle'), get_param(get_param(src_port_handle, 'Parent'), 'PortHandles').LConn)
                            p1 = p1.LConn(src_block_number);
                        else
                            p1 = p1.RConn(src_block_number);
                        end
                        p2 = get_param(Helper.full_path(copy_to.get_qualified_name, dst_block_new), "PortHandles");
                        if ismember(get_param(dst_port_handle, 'Handle'), get_param(get_param(dst_port_handle, 'Parent'), 'PortHandles').LConn)
                            p2 = p2.LConn(dst_block_number);
                        else
                            p2 = p2.RConn(dst_block_number);
                        end
                        add_line(copy_to.get_qualified_name, p1, p2, 'autorouting', 'on');
                    otherwise
                        keyboard
                end
            end
        end


        function holes = copy_SS(copy_from, copy_to, original_children, new_children)
            %if ~bdIsLoaded(copy_from.get_model_name)
            %    load_system(copy_from.model_path)
            %end
            [holes, dict] = ModelMutator.init(copy_to, original_children, new_children);

            inner_blocks = find_system(copy_from.get_qualified_name, 'LookUnderMasks', 'on', 'FollowLinks','on', 'Variants','AllVariants', 'IncludeCommented', 'on', 'SearchDepth', 1);
            holes = ModelMutator.insert_blocks(copy_to, inner_blocks, dict, holes);
            

            inner_lines = Helper.find_lines(copy_from.get_qualified_name, 1);
            ModelMutator.insert_lines(copy_to, dict, inner_lines);            
            ModelMutator.annotate(copy_to.get_qualified_name(), "Copied system from: " + copy_from.hash() + newline + "to: " + copy_to.hash())
        end

        function annotate(system, text)
            a = Simulink.Annotation(system, string(randi(1000)));
            a.FontSize = 18;
            a.BackgroundColor = 'lightBlue';
            a.Text = text;
        end
    end
end