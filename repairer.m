function repairer(model_name)%, model_url)
    if ~bdIsLoaded(model_name) 
        %load_system(model_url)
        error "Model not loaded"
    end

    gotos =  find_system(model_name, 'FollowLinks','on', 'IncludeCommented', 'on', 'Variants','AllVariants', 'Lookundermasks','on', 'BlockType','Goto');
    for i=1:numel(gotos)
        try
            set_param(gotos{i}, 'TagVisibility', 'local');
        catch
        end
    end


    toworkspaces = find_system(model_name, 'FollowLinks','on', 'IncludeCommented', 'on', 'Variants','AllVariants', 'Lookundermasks','on', 'BlockType','ToWorkspace');
    for i=1:numel(toworkspaces)
        try
            set_param(toworkspaces{i}, 'VariableName', ['var_name_' num2str(i)]);
        catch
        end
    end



    
    sfunctions = find_system(model_name, 'FollowLinks','on', 'IncludeCommented', 'on', 'Variants','AllVariants', 'Lookundermasks','on', 'BlockType','S-Function');
    for i=1:numel(sfunctions)
        try
            delete_block(sfunctions{i});
        catch
        end
    end
end
