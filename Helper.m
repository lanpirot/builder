classdef Helper
    properties(Constant)
        models_path = system_constants.models_path
        project_dir = system_constants.project_dir
        log_path = system_constants.project_dir + "logs" + system_constants.dir_separator


        project_info = Helper.log_path + "project_info.tsv";
        name2subinfo = Helper.log_path + "name2subinfo.json";


        uuid = 'UUID';
        identity = 'IDENTITY';
        sub_name = "sub_name";
        sub_parents = "sub_parents";
        model_path = "model_path";
        interface = 'INTERFACE'
        is_root = 'IS_ROOT'
        num_contained_elements = 'NUM_CONTAINED_ELEMENTS'
        sub_depth = 'SUB_DEPTH'
        subtree_depth = 'SUBTREE_DEPTH'
        
        

        log_garbage_out = Helper.log_path + "log_garbage_out";
        log_eval = Helper.log_path + "log_eval";
        log_close = Helper.log_path + "log_close";
        log_switch_up = Helper.log_path + "log_switch_up";
        log_compile = Helper.log_path + "log_compile";
        log_copy_to_missing = Helper.log_path + "log_copy_to_missing";

        modellist = Helper.log_path + "modellist.csv";

        
        garbage_out = Helper.project_dir + "tmp_garbage";
        playground = Helper.project_dir + "playground";


        project_id_pwd_number = system_constants.project_pwd_number;

        interface_header = "UUID,ChildUUIDs,Subsystem Path,Model Path,Project URL,Inports,Outports,...";

        first_level_divider = ",";
        second_level_divider = ";";
        third_level_divider = "+";


        remove_duplicates = 1;      %don't include subsystems which are very probably duplicates: same interface and same number of contained elements
        dimensions = 0
        data_types = 0              %data types shall be considered for equivalence
        needs_to_be_compilable = Helper.dimensions || Helper.data_types

        input_output_number_compability = 0     %a subsystem can be exchanged, if the other subsystem has less inputs and more outputs (that are all equivalent)


        depth = 'DEPTH'
        diverseness = 'DIVERSENESS'
        

        random = "RANDOM"
        mono = "MONO"
        diverse = "DIVERSE"
        shallow = "SHALLOW"
        deep = "DEEP"
        wish_property = Helper.deep     %set to one of above to build models of a certain property
    end
    
    methods(Static)
        function af = found_alt(found)
            persistent alts_found
            if isempty(alts_found)
                alts_found = 0;
            end
            alts_found = alts_found + found;
            af = alts_found; %otherwise it won't work with the 'persistent' qualification of alts_found
        end

        function subsystems = parse_json(file)
            subsystems = jsondecode(fileread(file));
        end

        function subsystems = find_subsystems(handle)
            subsystems = find_system(handle, 'LookUnderMasks','on', 'FollowLinks','On', 'BlockType','SubSystem'); %FollowLinks for building mode, without for clone find mode
        end

        function elements = find_elements(subsystem_handle)
            elements = find_system(subsystem_handle, 'LookUnderMasks', 'on', 'FollowLinks','on');
        end

        function ports = find_ports(subsystem_handle, block_type_string)
            ports = find_system(subsystem_handle, 'FindAll','On', 'LookUnderMasks','on', 'FollowLinks','On', 'SearchDepth',1, 'BlockType',block_type_string);
        end

        function depth = find_local_depth(handle)
            depth = 0;
            last_length = 0;
            while 1
                next_length = length(find_system(handle, 'FindAll','On', 'LookUnderMasks','on', 'FollowLinks','On', 'SearchDepth',depth));
                if next_length > last_length
                    last_length = next_length;
                else
                    break
                end
                depth = depth + 1;
            end
        end

        function diverseness = find_diverseness(handle)
            blocks = find_system(handle, 'LookUnderMasks', 'on', 'FollowLinks','on', 'Type','Block');
            block_types = {};
            for i=1:length(blocks)
                block_type = get_param(blocks(i), 'BlockType');
                if ~ismember(block_type, block_types)
                    block_types{end + 1} = block_type;
                end
            end
            diverseness = length(block_types);
        end

        function subsystems = get_contained_subsystems(handle)
            pot_subsystems = Helper.find_subsystems(handle);
            subsystems = [];
            for i = 2:length(pot_subsystems)
                if Subsystem.is_subsystem(pot_subsystems(i))
                    subsystems(end + 1) = pot_subsystems(i);
                end
            end
        end

        function info = get_info(n2i, name, field)%gets subsystem information from name2info.json
            info = n2i({char(name)});
            info = info{1}.(field);
        end            

        function str = rstrip(str)
            str = split(str, ' ');
            str = str{1};
        end

        function [arr, sortIdx] = sort_by_field(arr, field)
            sortIdx = [];
            if isempty(arr)
                return
            end
            if ischar(arr(1).(field))
                for i = 1:length(arr)
                    arr(i).(field) = string(arr(i).(field));
                end
            end

            [~, sortIdx] = sort([arr.(field)]);
            arr = arr(sortIdx);
        end

        function depth = get_depth(handle)
            parent = get_param(handle, 'Parent');
            if isempty(parent)
                depth = 0;
            else
                depth = 1 + count(string(parent).replace("//", "/"), "/");
            end
        end

        function is_root = is_rootf(handle)
            is_root = isempty(get_param(handle, 'Parent'));
        end

        function hash = get_hash(ports)
            if isempty(ports)
                hash = "";
            else
                hash = join(horzcat(ports.hsh), ";");
            end
        end

        function model_name = get_model_name(model_path)
                tmp = split(model_path, '/');
                tmp = split(tmp{end}, '.');
                model_name = tmp{1};
        end

        function parents = change_root_parent(old_parents, root_name)
            if isempty(old_parents)
                parents = '';
                return
            end
            tmp = split(old_parents, '/');
            tmp{1} = root_name;
            tmp = join(horzcat(tmp), '/');
            parents = tmp{1};
        end

        function file_print(file_name, message)
            my_fileID = fopen(file_name, "a+");
            message = replace(message, '\"', '\\"');
            fprintf(my_fileID, message);
            fclose(my_fileID);
        end

        function create_garbage_dir()
            mkdir(Helper.garbage_out)
            cd(Helper.garbage_out)
        end

        function clear_garbage()
            try
                rmdir(Helper.garbage_out + "*", 's');
            catch ME
                %log(Helper.project_dir, 'log_garbage_out', ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            end
            cd(Helper.project_dir)
        end

        function log(file_name, message)
            file_name = Helper.(file_name);
            my_fileID = fopen(file_name, "a+");
            fprintf(my_fileID, replace(string(message), "\", "/") + newline);
            fclose(my_fileID);
        end

        function reset_logs(file_list)
            for i = 1:length(file_list)
                file = file_list(i);
                my_fileID = fopen(file, "w+");
                fprintf(my_fileID, "");
                fclose(my_fileID);
            end
        end

        function mapping = get_one_mapping(ports1, ports2)
            mapping = [];
            for i = 1:length(ports1)
                mapping(end + 1) = Helper.find_equivalent_port(ports1(i), ports2, mapping);
                if mapping(end) < 0
                    mapping = [];
                    return
                end
            end
        end

        function index = find_equivalent_port(port, ports, mapped)
            index = -1;
            for i = 1:length(ports)
                if ~ismember(i, mapped) && all(port.dimensions.dimensions == ports(i).dimensions.dimensions) && strcmp(port.data_type, ports(i).data_type)
                    index = i;
                    return
                end
            end
        end

        function bool = special_ports_equi(s1, s2)
            bool = 0;
            if length(s1) == length(s2)
                if isempty(s1)
                    bool = 1;
                else
                    if length([s1.port_type]) == length([s2.port_type]) && all([s1.port_type] == [s2.port_type])
                        bool = 1;
                    end
                end
            end
        end
    end
end
