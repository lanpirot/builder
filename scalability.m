warning('off', 'all');
Helper.cfg('reset');
new_system();


% Get all .slx and .mdl files in the specified path
modelFiles = dir(fullfile(Helper.cfg.synthed_models_path, '**/', '*.slx'));
modelFiles = [modelFiles; dir(fullfile(Helper.cfg.synthed_models_path, '**/', '*.mdl'))];

path = '/home/lanpirot/data/builder/archive3/tamemodels/';
modelFiles = dir(fullfile(path, '**/', '*.slx'));
modelFiles = [modelFiles; dir(fullfile(path, '**/', '*.mdl'))];

% Open scalability.csv for writing
csvFile = fullfile(Helper.cfg.synthed_models_path, 'scalability.csv');
if exist(csvFile, 'file') == 2
    fid = fopen(csvFile, 'a');
else
    fid = fopen(csvFile, 'w');
    % Write CSV header
    fprintf(fid, 'Model Path,Model Size,Load Time (s),Find All Time (s),Num Elements,Save Time (s),Clone Time (s),Compile Time (s),Close Time (s)');
end
startnum = count(fileread(csvFile), newline);
if startnum < 1
    startnum = 1;
else
    startnum = startnum + 2;
end

% Generic timing function
function time = test_metric(modelPath, function_metric)
    tic;
    try
        function_metric(modelPath);
        time = toc;
    catch ME
        time = NaN;
    end
end

function [time, num_elements] = find_all_elements()
    tic
    elements = find_system(gcs, 'FindAll','on', 'LookUnderMasks', 'on', 'FollowLinks','on', 'IncludeCommented', 'on', 'Variants','AllVariants');
    time = toc;
    num_elements = length(elements);
end

function time = save_model()
    tempFile = 'tempname.slx';
    tic;
    save_system(gcs, tempFile);
    time = toc;
    close_system('tempname');
    if exist(tempFile, 'file')
        delete(tempFile);
    end
end


startnum = 2800;

% Process each model
for i = startnum:length(modelFiles)

    modelPath = fullfile(modelFiles(i).folder, modelFiles(i).name);
    %if contains(modelFiles(i).folder, 'tame') || contains(modelPath, '0/RANDOM/model365.slx') || contains(modelPath, '0/RANDOM/model853.slx')
    %    continue
    %end

    fprintf(fid, '\n');
    bdclose all;

    modelName = split(modelFiles(i).name, ".");
    modelName = modelName{1};
    fprintf('Processing %s...\n', modelPath);

    fileInfo = dir(modelPath);
    sizeBytes = fileInfo.bytes;

    % Load model
    loadTime = test_metric(modelPath, @load_system);

    if isempty(gcs)
        continue
    end

    % Find all elements
    [findTime, numElements] = find_all_elements();

    % compile
    try
        tic
        %eval([modelName, '([],[],[],''compile'');']);
        compileTime = toc;
        try
            while 1
                eval([modelName, '([],[],[],''term'');']);
            end
        catch
        end
    catch ME
        compileTime = NaN;
    end

    % Save model
    try
        saveTime = save_model();
    catch ME
        if strcmp(ME.identifier, 'Simulink:Commands:SaveModelCallbackError')
            continue
        end
    end
    test_metric(modelPath, @load_system);

    % Find clones
    cloneTime = test_metric(modelPath, @Simulink.CloneDetection.findClones);

    % Close model    
    closeTime = test_metric(modelName, @close_system);

    % Write results to CSV
    fprintf(fid, '%s,%d,%.6f,%.6f,%d,%.6f,%.6f,%.6f,%.6f', ...
            modelPath, ...
            sizeBytes, ...
            loadTime, ...
            findTime, ...
            numElements, ...
            saveTime, ...
            cloneTime, ...
            compileTime, ...
            closeTime);
end

% Close the CSV file
fclose(fid);
fprintf('Results written to %s\n', csvFile);