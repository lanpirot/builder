function complete_script()
    gather_models()
    miner()
    if Helper.remove_duplicates
        builder()
    end
end

%run by using the following:
%matlab -nodisplay -nosplash -nodesktop -r "run('gather_models()');run('complete_script()');exit;"