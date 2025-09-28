classdef Helper

    properties(Constant)
        uuid = 'UUID';
        identity = 'IDENTITY';
        sub_name = "sub_name";
        sub_parents = "sub_parents";
        model_path = "model_path";
        interface = 'INTERFACE'
        is_root = 'IS_ROOT'
        
        %Subsystem.m
        num_local_elements = 'NUM_LOCAL_ELEMENTS'
        local_depth = 'LOCAL_DEPTH'
        subtree_depth = 'SUBTREE_DEPTH'
        children = 'DIRECT_CHILDREN'

        %report
        num_subsystems = 'NUM_SUBSYSTEMS'
        unique_models = 'UNIQUE_MODELS'
        unique_subsystems = 'UNIQUE_SUBSYSTEMS';


        interface_header = "UUID,ChildUUIDs,Subsystem Path,Model Path,Project URL,Inports,Outports,...";

        first_level_divider = ",";
        second_level_divider = ";";
        third_level_divider = "+";

        input_output_number_compability = 0     %a subsystem can be exchanged, if the other subsystem has less inputs and more outputs (that are all equivalent)


        depth = 'DEPTH'
        

        random = "RANDOM"
        shallow = "SHALLOW"
        deep = "DEEP"


        synth_random =    'RANDOM';                 %just try to synthesize any model
        synth_AST_model = 'AST_MODEL'               %try to emulate a given model's subtree
        synth_width =     'WIDTH'                   %try to fill every level of the model until max_depth
        synth_giant =     'GIANT'                   %build giant models, efficiently
        synth_depth =     'DEPTH'                   %try to create a deep model
    end
    
    methods(Static)
        function out = cfg(field, value)
            persistent cfg;
            if nargin == 1 && strcmp(field, 'reset')
                cfg = [];
            end
            if isempty(cfg)
                assert(nargin == 0 || strcmp(field, 'reset') || strcmp(field, 'cfg'))
                cfg = struct();
                cfg.models_path = system_constants.models_path;
                cfg.project_dir = system_constants.project_dir;
                cfg.tame_models_path = system_constants.tame_models_path;
                cfg.log_path = system_constants.project_dir;
                mkdir(cfg.log_path)
                cfg.project_info = fullfile(cfg.log_path, "project_info.tsv");
                cfg.modellist = fullfile(cfg.log_path, "modellist.csv");
                cfg.garbage_out = fullfile(cfg.log_path, "tmp_garbage");
            end
            if nargin == 2
                if strcmp(field, 'cfg') && isstruct(value)
                    cfg = value;
                    out = cfg;
                    return
                end
                if ismember(field, fields(cfg))
                    error("Field in config already set in Helper.cfg!")
                end
                cfg.(field) = value;
                if strcmp('needs_to_be_compilable', field)
                    cfg.dimensions = value;
                    cfg.data_types = value;
                    exp1path = fullfile(cfg.log_path, string(value));
                    mkdir(exp1path)
                    cfg.exp1path = exp1path;
                    cfg.interface2subs = fullfile(exp1path, "interface2subs.json");
                    cfg.name2subinfo_complete = fullfile(exp1path, "name2subinfo_complete.json");
                    cfg.name2subinfo = fullfile(exp1path, "name2subinfo.json");
                    cfg.garbage_out = fullfile(exp1path, "tmp_garbage");
                    cfg.log_garbage_out = fullfile(exp1path, "log_garbage_out");
                    cfg.log_eval = fullfile(exp1path, "log_eval");
                    cfg.log_close = fullfile(exp1path, "log_close");
                    cfg.models_mined = fullfile(cfg.log_path, "models_mined.csv");
                end
                if ismember('needs_to_be_compilable', fields(cfg)) && ismember('synth_mode', fields(cfg))
                    exp2path = fullfile(cfg.exp1path, cfg.synth_mode);
                    mkdir(exp2path)
                    cfg.exp2path = exp2path;
                    cfg.garbage_out = fullfile(exp2path, "tmp_garbage");
                    cfg.synthesize_playground = exp2path;
                    cfg.synth_report = fullfile(exp2path, "synth_report.csv");
                    cfg.log_garbage_out = fullfile(exp2path, "log_garbage_out");
                    cfg.log_switch_up = fullfile(exp2path, "log_switch_up");
                    cfg.log_compile = fullfile(exp2path, "log_compile");
                    cfg.log_copy_to_missing = fullfile(exp2path, "log_copy_to_missing");
                    cfg.log_synth_theory = fullfile(exp2path, "log_synth_theory");
                    cfg.log_synth_practice = fullfile(exp2path, "log_synth_practice");
                end
            end
            %config.mutate_playground = config.exp2path + "mutate_playground";
            out = cfg;
        end

        function synth_profile(synth_mode, needs_to_be_compilable, dry, check, diverse, roots_only)
            global synth
            set(0, 'RecursionLimit', 500)
            Helper.cfg();
            Helper.cfg('synth_mode', synth_mode);
            Helper.cfg('needs_to_be_compilable', needs_to_be_compilable);
            synth.mode = synth_mode;
            synth.needs_to_be_compilable = needs_to_be_compilable;
            synth.dry_build = dry;
            synth.double_check_file = check;
            synth.force_diversity = diverse;
            synth.seed_with_roots_only = roots_only;
            synth.time_out = 300;
            switch synth_mode
                case Helper.synth_random
                    synth.model_count = 1000;
                    synth.repair_level_count = 3;
                    synth.repair_root_count = synth.repair_level_count;
                    synth.choose_sample_size = 10;
                    synth.mutate_chances = 100;
                    synth.choose_retries = 10;
                    synth.max_depth = 20;
                case Helper.synth_AST_model
                    synth.model_count = 1000;
                    synth.repair_level_count = 2;
                    synth.repair_root_count = synth.repair_level_count;
                    synth.choose_sample_size = 10;
                    synth.mutate_chances = 100;
                    synth.choose_retries = 5;
                    synth.max_depth = 20;
                case Helper.synth_width
                    synth.model_count = 100;
                    synth.repair_level_count = 3;
                    synth.repair_root_count = synth.repair_level_count;
                    synth.choose_sample_size = 5;
                    synth.mutate_chances = 100;
                    synth.choose_retries = 5;
                    synth.min_height = 8;
                    synth.max_depth = 12;
                case Helper.synth_giant
                    synth.model_count = 100;
                    synth.repair_level_count = 3;
                    synth.repair_root_count = synth.repair_level_count;
                    synth.choose_sample_size = 10;
                    synth.mutate_chances = 100;
                    synth.choose_retries = 10;
                    synth.max_depth = 20;
                    if synth.needs_to_be_compilable
                        synth.slnet_max_depth =     7;           
                        synth.slnet_max_elements =  1122;              
                        synth.slnet_max_subs =      146;      
                    else
                        synth.slnet_max_depth =     17;
                        synth.slnet_max_elements =  108523;
                        synth.slnet_max_subs =      15800;
                    end
                case Helper.synth_depth
                    synth.model_count = 100;
                    synth.repair_level_count = 3;
                    synth.repair_root_count = synth.repair_level_count;
                    synth.choose_sample_size = 10;
                    synth.mutate_chances = 100;
                    synth.choose_retries = 5;
                    if synth.needs_to_be_compilable
                        synth.min_depth = 30;
                    else
                        synth.min_depth = 50;
                    end
                    synth.max_depth = 100;
                    set(0, 'RecursionLimit', 5000)
            end
        end

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

            sub_identities = extractfield(name2subinfo, lower(Helper.identity));
            sub_interfaces = extractfield(name2subinfo, lower(Helper.interface));
        
            sub_num_local_elements = num2cell(extractfield(name2subinfo, lower(Helper.num_local_elements)));
            local_depths = num2cell(extractfield(name2subinfo, lower(Helper.local_depth)));
            subtree_depth = num2cell(extractfield(name2subinfo, lower(Helper.subtree_depth)));
            children = extractfield(name2subinfo, lower(Helper.children));    
            
            sub_info = [sub_identities; sub_interfaces; sub_num_local_elements; local_depths; subtree_depth; children];
            sub_info = cell2struct(sub_info, {Helper.identity, Helper.interface, Helper.num_local_elements, Helper.local_depth, Helper.subtree_depth, Helper.children});
            out = num2cell(sub_info);
            name2subinfo = dictionary(sub_identities', out);
        end



        %TODO: 'IncludeCommented', 'on'
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

        function lines = find_lines(subsystem_handle, depth)
            if ~exist('depth', 'var')
                lines = find_system(subsystem_handle, 'FindAll','on', 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'Type','line');
            else
                lines = find_system(subsystem_handle, 'FindAll','on', 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'SearchDepth',depth, 'Type','line');
            end
        end

        function depth = find_subtree_depth(handle)
            depth = 0;
            last_length = 0;
            while 1
                next_length = length(find_system(handle, 'LookUnderMasks','on', 'FollowLinks','on', 'Variants','AllVariants', 'SearchDepth',depth));
                if next_length > last_length
                    last_length = next_length;
                else
                    break
                end
                depth = depth + 1;
            end
        end

        function num = find_num_elements_in_contained_subsystems(handle)
            subsystems = Helper.get_contained_subsystems(handle, 10000);
            num = length(Helper.find_elements(handle, 1));
            for i = 1:length(subsystems)
                num = num + length(Helper.find_elements(subsystems(i), 1));
            end
        end

        function path = full_path(varargin)
            path = '';
            for v = 1:numel(varargin)
                if isempty(path)
                    path = varargin{v};
                else
                    path = [path '/' varargin{v}];
                end
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
            %message = replace(message, '\"', '\\"');
            fprintf(my_fileID, "%s", message);
            fclose(my_fileID);
        end

        function create_garbage_dir()
            mkdir(Helper.cfg().garbage_out)
            cd(Helper.cfg().garbage_out)
        end

        function clear_garbage()
            try
                rmdir(Helper.cfg().garbage_out + "*", 's');
            catch ME
                %log(Helper.cfg().project_dir, 'log_garbage_out', ME.identifier + " " + ME.message + newline + string(ME.stack(1).file) + ", Line: " + ME.stack(1).line);
            end
            cd(Helper.cfg().project_dir)
        end

        function clean_up(startmessage, playground_path, logs)
            set(0, 'DefaultFigureVisible', 'off');
            warning('off','all')
            disp(startmessage)
            mkdir(playground_path)
            delete(playground_path + filesep + "*");
            Helper.reset_logs(logs);
            %clear('all');
        end

        function out = with_preserved_cfg(fn, varargin)
            global name2subinfo_complete model2id interface2subs depth_reached synth
            
            savename2subinfo_complete = name2subinfo_complete;
            savemodel2id = model2id;
            saveinterface2subs = interface2subs;
            savedepth_reached = depth_reached;
            savesynth = synth;
            savecfg = Helper.cfg();

            if nargout == 0
            % Run the operation
                fn(varargin{:});
            else
               out = fn(varargin{:});
            end
        
            name2subinfo_complete = savename2subinfo_complete;
            model2id = savemodel2id;
            interface2subs = saveinterface2subs;
            depth_reached = savedepth_reached;
            synth = savesynth;
            Helper.cfg("cfg", savecfg);
        end

        function log(file_name, message)
            file_name = Helper.cfg().(file_name);
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
            global synth
            bool = strcmp(synth.mode, mode);
        end
    end
end
