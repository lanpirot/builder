classdef system_constants
    properties (Constant = true)
        dir_separator = "\"
        %dir_separator = "/"
        
        
        models_path = "C:\svns\simucomp2\models\SLNET_v1\SLNET";
        project_dir = "C:\svns\alex projects\builder\";
        log_path = system_constants.project_dir + "logs\"


        project_info = system_constants.log_path + "project_info.tsv";

        interface2name = system_constants.log_path + "interface2name.json";
        interface2name_unique = system_constants.log_path + "interface2name_unique.json";
        name2subinfo = system_constants.log_path + "name2subinfo.json";
        name2subinfo_roots = system_constants.log_path + "name2subinfo_roots.json";
        

        log_garbage_out = system_constants.log_path + "log_garbage_out";
        log_eval = system_constants.log_path + "log_eval";
        log_close = system_constants.log_path + "log_close";
        log_switch_up = system_constants.log_path + "log_switch_up";
        log_construct = system_constants.log_path + "log_construct";

        modellist = system_constants.log_path + "modellist.csv";

        
        garbage_out = system_constants.project_dir + "garbage_out";
        playground = system_constants.project_dir + "playground";
    end
end