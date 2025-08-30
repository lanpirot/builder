function clean_models()
    % Load constants
    bdclose all;
    set(0, 'DefaultFigureVisible', 'off');
    warning('off','all')
    LOCATION = Helper.cfg().models_path;
    NEWLOCATION = Helper.cfg().good_models_path;
    if ~exist(NEWLOCATION, 'dir')
        mkdir(NEWLOCATION); % Create the new location if it doesn't exist
    end

    % State file to track last processed model
    state_file = fullfile(NEWLOCATION, 'last_processed_model.txt');

    % Recursively get all .slx and .mdl files
    files_slx = dir(fullfile(LOCATION, '**', '*.slx'));
    files_mdl = dir(fullfile(LOCATION, '**', '*.mdl'));
    files = [files_slx; files_mdl];
    total_models = numel(files);

    % Read state file to skip already processed models
    last_processed = 0;
    if exist(state_file, 'file')
        fid = fopen(state_file, 'r');
        last_processed = str2double(fgetl(fid));
        fclose(fid);
    end

    % Process models
    for i = 1:total_models
        model_file = files(i).name;
        model_path = fullfile(files(i).folder, model_file);

        % Skip already processed models
        if i <= last_processed
            continue;
        end

        try
            fprintf('Processing model %d of %d: %s\n', i, total_models, model_path);

            % Update state file
            fid = fopen(state_file, 'w');
            fprintf(fid, '%i', i);
            fclose(fid);

            % Load model
            model = load_system(model_path);

            set_param(model, 'Lock', 'off');
            % Remove all callback functions for the model
            model_functions = {'PreLoadFcn' 'PostLoadFcn' 'InitFcn' 'PreStartFcn' 'StartFcn' 'PauseFcn' 'StopFcn' 'ContinueFcn' 'CloseFcn' 'CleanupFcn' 'PreSaveFcn' 'PostSaveFcn' 'SetupFcn' 'CustomCommentsFcn' 'DefineNamingFcn' 'ParamNamingFcn' 'SignalNamingFcn'};
            for m = 1:length(model_functions)
                set_param(model, model_functions{m}, '');
            end



            lock_links = {'LinkStatus', 'none'; 'Lock', 'off'; 'LockLinksToLibrary', 'off'};
            block_functions = {'OpenFcn' 'LoadFcn' 'MoveFcn' 'NameChangeFcn' 'PreCopyFcn' 'CopyFcn' 'ClipboardFcn' 'PreDeleteFcn' 'DeleteFcn' 'DestroyFcn' 'UndoDeleteFcn' 'InitFcn' 'StartFcn' 'ContinueFcn' 'PauseFcn' 'StopFcn' 'PreSaveFcn' 'PostSaveFcn' 'CloseFcn' 'ModelCloseFcn'};
            blocks = Helper.find_elements(model);
            for j = 2:numel(blocks)
                for ll = 1:size(lock_links, 1)
                    try
                        set_param(blocks(j), lock_links{ll, 1}, lock_links{ll, 2});
                    catch ME
                    end
                end

                for bf = 1:length(block_functions)
                    try
                        set_param(blocks(j), block_functions{bf}, '');
                    catch ME
                    end
                end
            end

            % Save cleaned model
            [~, name, ext] = fileparts(model_file);
            new_name = sprintf('m%d%s%s', i, name, ext);
            save_system(model, fullfile(NEWLOCATION, new_name), 'BreakLinks', true);
            close_system(model);

            

            bdclose all;
            fprintf('Successfully processed: %s\n', model_path);
        catch ME
            fprintf('Model %d failed: %s\nReason: %s\n', i, model_path, ME.message);
            bdclose all;
        end
    end
    fprintf('Processing complete.\n');
end
