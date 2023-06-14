classdef SampleTime
    properties
        sample_start
        sample_diff
    end

    methods
        function obj = SampleTime(time)
            if ~exist('time', 'var')
                obj.sample_start = 0;
                obj.sample_diff = 0;
                return
            end

            if height(time) == 1
                obj.sample_start = time(1);
                obj.sample_diff = time(2);
                return
            end
            for i = 1:height(time)
                t = time{i};
                obj.sample_start(end + 1) = t(1);
                obj.sample_diff(end + 1) = t(2);
            end
        end

        function str = print(obj)
            str = "";
            for i = 1:length(obj.sample_start)
                str = str + string(obj.sample_start(i)) + " " + string(obj.sample_diff(i));
            end            
        end
    end

    methods(Static)
    end
end