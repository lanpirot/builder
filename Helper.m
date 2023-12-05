classdef Helper
    properties(Constant)
        models_path = system_constants.models_path
        project_dir = system_constants.project_dir
        log_path = system_constants.project_dir + "logs" + system_constants.dir_separator


        project_info = Helper.log_path + "project_info.tsv";
        interface2subs = Helper.log_path + "interface2subs.json"
        name2subinfo_complete = Helper.log_path + "name2subinfo_complete.json";
        name2subinfo = Helper.log_path + "name2subinfo.json";
        name2subinfo_chimerable = Helper.log_path + "name2subinfo_chimerable.json";


        uuid = 'UUID';
        identity = 'IDENTITY';
        sub_name = "sub_name";
        sub_parents = "sub_parents";
        model_path = "model_path";
        interface = 'INTERFACE'
        is_root = 'IS_ROOT'
        
        %Subsystem.m
        num_local_elements = 'NUM_LOCAL_ELEMENTS'
        local_depth = 'LOCAL_DEPTH' %sub_depth
        subtree_depth = 'SUBTREE_DEPTH'
        children = 'CHILDREN'

        log_garbage_out = Helper.log_path + "log_garbage_out";
        log_eval = Helper.log_path + "log_eval";
        log_close = Helper.log_path + "log_close";
        log_switch_up = Helper.log_path + "log_switch_up";
        log_compile = Helper.log_path + "log_compile";
        log_copy_to_missing = Helper.log_path + "log_copy_to_missing";
        log_synth_theory = Helper.log_path + "log_synth_theory";
        log_synth_practice = Helper.log_path + "log_synth_practice";


        modellist = Helper.log_path + "modellist.csv";

        
        garbage_out = Helper.project_dir + "tmp_garbage";
        mutate_playground = Helper.project_dir + "mutate_playground";
        synthesize_playground = Helper.project_dir + "synthesize_playground";

        %report
        num_subsystems = 'NUM_SUBSYSTEMS'
        unique_models = 'UNIQUE_MODELS'
        unique_subsystems = 'UNIQUE_SUBSYSTEMS';
        synth_report = Helper.synthesize_playground + filesep + "synth_report.csv";


        project_id_pwd_number = system_constants.project_pwd_number;

        interface_header = "UUID,ChildUUIDs,Subsystem Path,Model Path,Project URL,Inports,Outports,...";

        first_level_divider = ",";
        second_level_divider = ";";
        third_level_divider = "+";


        dimensions = 0
        data_types = 0
        needs_to_be_compilable = Helper.dimensions || Helper.data_types

        input_output_number_compability = 0     %a subsystem can be exchanged, if the other subsystem has less inputs and more outputs (that are all equivalent)


        depth = 'DEPTH'
        

        random = "RANDOM"
        shallow = "SHALLOW"
        deep = "DEEP"
        wish_property = Helper.deep     %set to one of above to build models of a certain property

        synth_dry_build = 0;
        synth_double_check = 0;
        synth_force_diversity = 1;
        synth_seed_with_roots_only = 1;

        synth_model_count = 1000;
        synth_repair_count = 3;
        synth_random = 'RANDOM';                    %just try to synthesize any model
        synth_AST_model = 'AST_MODEL'               %try to emulate a given model's subtree
        synth_width = 'WIDTH'                       %try to fill every level of the model until max_depth
        synth_giant = "GIANT"                       %build giant models, efficiently
        synth_depth = 'DEPTH'                       %try to create a deep model
        synth_sample_size = 10;
        synth_mode = Helper.synth_giant
        synth_max_depth = 50;


        slnet_max_depth = 15;                       %SLNET max: 15
        slnet_max_elements = 106823;                %SLNET max: 106823
        slnet_max_subs = 13501;                     %SLNET max: 13501

        %slnet_max_depth = 5;                       %SLNET max: 15
        %slnet_max_elements = 106;                %SLNET max: 106823
        %slnet_max_subs = 13;                     %SLNET max: 13501
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

        function name2subinfo = build_sub_info(name2subinfo)
            name2subinfo = name2subinfo';
            sub_identities = extractfield(name2subinfo, Helper.identity);
            

            sub_identities = extractfield(name2subinfo, Helper.identity);    
            sub_interfaces = extractfield(name2subinfo, Helper.interface);
        
            sub_num_local_elements = num2cell(extractfield(name2subinfo, Helper.num_local_elements));
            local_depths = num2cell(extractfield(name2subinfo, Helper.local_depth));
            subtree_depth = num2cell(extractfield(name2subinfo, Helper.subtree_depth));
            children = extractfield(name2subinfo, Helper.children);    
            
            sub_info = [sub_identities; sub_interfaces; sub_num_local_elements; local_depths; subtree_depth; children];
            sub_info = cell2struct(sub_info, {Helper.identity, Helper.interface, Helper.num_local_elements, Helper.local_depth, Helper.subtree_depth, Helper.children});
            out = {};
            for i=1:length(sub_info)
                out{end + 1} = sub_info(i);
            end
            name2subinfo = dictionary(sub_identities, out);
        end

        function subsystems = find_subsystems(handle, depth)
            if ~exist('depth', 'var')
                subsystems = find_system(handle, 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'BlockType','SubSystem'); %FollowLinks for building mode, without for clone find mode
            else
                subsystems = find_system(handle, 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'SearchDepth',depth, 'BlockType','SubSystem'); %FollowLinks for building mode, without for clone find mode
            end
        end

        function elements = find_elements(subsystem_handle, depth)
            if ~exist('depth', 'var')
                elements = find_system(subsystem_handle, 'LookUnderMasks', 'on', 'FollowLinks','on', 'Variants','AllVariants');
            else
                elements = find_system(subsystem_handle, 'LookUnderMasks', 'on', 'FollowLinks','on', 'Variants','AllVariants', 'SearchDepth',depth);
            end
        end

        function ports = find_ports(subsystem_handle, block_type_string)
            ports = find_system(subsystem_handle, 'FindAll','on', 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'SearchDepth',1, 'BlockType',block_type_string);
        end

        function depth = find_subtree_depth(handle)
            depth = 0;
            last_length = 0;
            while 1
                next_length = length(find_system(handle, 'FindAll','on', 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'SearchDepth',depth));
                if next_length > last_length
                    last_length = next_length;
                else
                    break
                end
                depth = depth + 1;
            end
        end

        function num = find_num_elements_in_contained_subsystems(handle)
            subsystems = Helper.get_contained_subsystems(handle, 1000);
            num = length(Helper.find_elements(handle, 1));
            for i = 1:length(subsystems)
                num = num + length(Helper.find_elements(subsystems(i), 1));
            end
        end

        function subsystems = get_contained_subsystems(handle, depth)
            pot_subsystems = Helper.find_subsystems(handle, depth);
            subsystems = [];
            if Helper.is_rootf(handle)
                min = 1;
            else
                min = 2;
            end
            for i = min:length(pot_subsystems)
                if Subsystem.is_subsystem(pot_subsystems(i))
                    subsystems(end + 1) = pot_subsystems(i);
                end
            end
        end

        function info = get_info(n2i, name, field)%gets subsystem information from name2info.json
            info = n2i{{char(name)}}.(field);
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
            fprintf(my_fileID, "%s", message);
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

        function clean_up(startmessage, playground_path, logs)
            warning('off','all')
            disp(startmessage)
            mkdir(playground_path)
            delete(playground_path + filesep + "*");
            Helper.reset_logs(logs);
            clear('all');
        end

        function log(file_name, message)
            file_name = Helper.(file_name);
            my_fileID = fopen(file_name, "a+");
            fprintf(my_fileID, "%s", replace(string(message), "\", "/") + newline);
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

        function bool = is_synth_mode(mode)
            bool = strcmp(Helper.synth_mode, mode);
        end
    end
end
