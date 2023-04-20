classdef helper
    properties(Constant)
        models_path = "C:\svns\simucomp2\models\SLNET_v1\SLNET";
        tmp_models_path = "C:\svns\simucomp2\models\SLNET_v1\SLNET\SLNET_GitHub\7269901";
        project_info = "C:\svns\alex projects\builder\project_info.tsv";

        subsystem_interfaces = "C:\svns\alex projects\builder\logs\subsystem_interfaces";
        log_garbage_out = "C:\svns\alex projects\builder\logs\log_garbage_out";
        log_load_system = "C:\svns\alex projects\builder\logs\log_load_system";
        log_eval = "C:\svns\alex projects\builder\logs\log_eval";
        log_close = "C:\svns\alex projects\builder\logs\log_close";

        project_dir = "C:\svns\alex projects\builder";
        garbage_out = "C:\svns\alex projects\builder\garbage_out";

        modellist = "C:\svns\alex projects\builder\modellist.csv";
        tmp_modellist = "C:\svns\alex projects\builder\tmp_modellist.csv";
        startat = "C:\svns\alex projects\builder\startat.txt";
        project_id_pwd_number = 8;
    end
    
    methods(Static)
        function str = rstrip(str)
            str = split(str, ' ');
            str = str{1};
        end

        function arr = sort_by_field(arr, field)
            if isempty(arr)
                return
            end
            [~, sortIdx] = sort([arr.(field)]);
            arr = arr(sortIdx);
        end

        function depth = get_depth(parent_str)
            depth = 1 + count(parent_str,"/");
        end
    end
end
