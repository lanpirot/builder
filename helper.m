classdef helper
    properties(Constant)
        models_path = "C:\svns\simucomp2\models\SLNET_v1\SLNET";
        tmp_models_path = "C:\svns\simucomp2\models\SLNET_v1\SLNET\SLNET_GitHub\7269901";
        project_info = "C:\svns\alex projects\builder\project_info.tsv";

        project_dir = "C:\svns\alex projects\builder";
        garbage_out = "C:\svns\alex projects\builder\garbage_out";

        modellist = "C:\svns\alex projects\builder\modellist.csv";
        tmp_modellist = "C:\svns\alex projects\builder\tmp_modellist.csv";
        startat = "C:\svns\alex projects\builder\startat.txt";
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
    end
end
