classdef Helper
    properties(Constant)
        models_path = system_constants.models_path
        project_dir = system_constants.project_dir
        log_path = system_constants.project_dir + "logs" + system_constants.dir_separator


        project_info = Helper.log_path + "project_info.tsv";

        interface2name = Helper.log_path + "interface2name.json";
        interface2name_unique = Helper.log_path + "interface2name_unique.json";
        name2subinfo = Helper.log_path + "name2subinfo.json";
        name2subinfo_roots = Helper.log_path + "name2subinfo_roots.json";
        

        log_garbage_out = Helper.log_path + "log_garbage_out";
        log_eval = Helper.log_path + "log_eval";
        log_close = Helper.log_path + "log_close";
        log_switch_up = Helper.log_path + "log_switch_up";
        log_construct = Helper.log_path + "log_construct";

        modellist = Helper.log_path + "modellist.csv";

        
        garbage_out = Helper.project_dir + "tmp_garbage";
        playground = Helper.project_dir + "playground";


        project_id_pwd_number = system_constants.project_pwd_number;

        interface_header = "UUID,ChildUUIDs,Subsystem Path,Model Path,Project URL,Inports,Outports,...";

        first_level_divider = ",";
        second_level_divider = ";";
        third_level_divider = "+";


        dimensions = 1
        data_types = 1              %data types shall be considered for equivalence
        sample_times = 0            %sample times shall be considered for equivalence
        needs_to_be_compilable = Helper.dimensions || Helper.data_types || Helper.sample_times

        name = 'NAME'
        names = 'NAMES'
        mapping = 'MAPPING'
        ntrf = 'INTERFACE'
        diverseness = 'DIVERSENESS'
        depth = 'DEPTH'        

        random = "RANDOM"
        mono = "MONO"
        diverse = "DIVERSE"
        shallow = "SHALLOW"
        deep = "DEEP"
        wish_property = Helper.shallow     %set to one of above to build models of a certain property
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

        function hash = get_hash(ports)
            if isempty(ports)
                hash = "";
            else
                hash = join(horzcat(ports.hsh), ";");
            end
        end

        function file_print(file_name, message)
            my_fileID = fopen(file_name, "a+");
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
    end
end
