function complete_script()
    gather_models()
    mine()
    if Helper.remove_duplicates
        mutate()
    end
end

%run by using the following:
%matlab -nodisplay -nosplash -nodesktop -r "run('gather_models()');run('complete_script()');exit;"